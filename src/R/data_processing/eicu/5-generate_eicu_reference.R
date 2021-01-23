rm(list=ls())

library(pracma)
library(tictoc)
library(glmnet)
library(ROCR)
library(matrixStats)
library(parallel)
library(ggplot2)
library(xgboost)
library(lubridate)

eicu.clinical.data = readRDS("eicu/clinical_data_icd9_sofa_vent.rds")
eicu.patient.result = readRDS("eicu/patient_data.rds")
eicu.sofa.scores = readRDS("eicu/sofa_scores.rds")

source("eicu_functions/generate_sampling_rate_table.R")
source("eicu_functions/eval_carry_forward.R")
source("eicu_functions/eval_interval.R")
source("eicu_functions/eval_max_in_past_2.R")
source("eicu_functions/eval_sum_in_past.R")
source("eicu_functions/eval_early_prediction_timestamps_combined_rf.R")
source("eicu_functions/eval_table_with_sofa_2.R")
source("eicu_functions/generate_table_with_sofa_timestamps.R")

lengths = sapply(eicu.sofa.scores, function(x) length(x$timestamps))
eicu.sepsis.labels = sapply(eicu.sofa.scores[lengths>0], function(x) rowSums(x[2:7])>=2)
eicu.has.sepsis = sapply(eicu.sepsis.labels, any)

# Determine shock onsets
eicu.shock.labels = mapply(function(x,y) x&y$lactate&y$vasopressors, eicu.sepsis.labels, eicu.sofa.scores[lengths>0])
eicu.has.shock = sapply(eicu.shock.labels, function(x) any(x,na.rm=T)) #& has.dx[lengths>0]

sepsis.label.lengths = sapply(eicu.sepsis.labels,length)
shock.lengths=sapply(eicu.shock.labels,length)
sofa.timestamps.lengths = sapply(eicu.sofa.scores[lengths>0],function(x)length(x$timestamps))

eicu.shock.onsets = mapply(function(x,y) min(x$timestamps[y],na.rm=T),eicu.sofa.scores[lengths>0][eicu.has.shock],eicu.shock.labels[eicu.has.shock])

# Generate table of sampling rates
tic("Generating sampling rate data")
sampling.rate.data = lapply(eicu.clinical.data, generate.sampling.rate.table)
toc()

num.cores = detectCores()
cluster = makeCluster(num.cores)
clusterExport(cluster,c("eval.table.with.sofa","eval.carry.forward","eval.sum.in.past","eval.max.in.past","eval.interval","generate.table.with.sofa.timestamps","eicu.sofa.scores","sampling.rate.data","eicu.shock.onsets","lengths","eicu.has.sepsis","eicu.has.shock"))

tic("Generate data tables (parallel)")
eicu.nonsepsis.data.sampling.rate = parLapply(cluster, 1:sum(!eicu.has.sepsis), function(x) generate.table.with.sofa.timestamps(min(eicu.sofa.scores[lengths>0][!eicu.has.sepsis][[x]]$timestamps),max(eicu.sofa.scores[lengths>0][!eicu.has.sepsis][[x]]$timestamps),100,sampling.rate.data[lengths>0][!eicu.has.sepsis][[x]]))
eicu.nonshock.data.sampling.rate = parLapply(cluster, 1:sum(eicu.has.sepsis&!eicu.has.shock), function(x) generate.table.with.sofa.timestamps(min(eicu.sofa.scores[lengths>0][eicu.has.sepsis&!eicu.has.shock][[x]]$timestamps),max(eicu.sofa.scores[lengths>0][eicu.has.sepsis&!eicu.has.shock][[x]]$timestamps),100,sampling.rate.data[lengths>0][eicu.has.sepsis&!eicu.has.shock][[x]]))
eicu.preshock.data.sampling.rate = parLapply(cluster, 1:sum(eicu.has.shock), function(x) generate.table.with.sofa.timestamps(eicu.shock.onsets[x]-120,eicu.shock.onsets[x]-60,100,sampling.rate.data[lengths>0][eicu.has.shock][[x]]))
toc()
stopCluster(cluster)


#num.cores = detectCores()
num.cores = 4
cluster = makeCluster(num.cores)
clusterExport(cluster,c("eval.table.with.sofa","eval.carry.forward","eval.sum.in.past","eval.max.in.past","eval.interval","generate.table.with.sofa.timestamps","eicu.sofa.scores","eicu.clinical.data","eicu.shock.onsets","lengths","eicu.has.sepsis","eicu.has.shock","eicu.nonsepsis.data.sampling.rate","eicu.nonshock.data.sampling.rate","eicu.preshock.data.sampling.rate"))
tic("Data tables (parallel)")
eicu.nonsepsis.data = parLapply(cluster, 1:sum(!eicu.has.sepsis), function(x) eval.table.with.sofa(eicu.nonsepsis.data.sampling.rate[[x]]$timestamps,eicu.clinical.data[lengths>0][!eicu.has.sepsis][[x]]))
eicu.nonshock.data = parLapply(cluster, 1:sum(eicu.has.sepsis&!eicu.has.shock), function(x) eval.table.with.sofa(eicu.nonshock.data.sampling.rate[[x]]$timestamps,eicu.clinical.data[lengths>0][eicu.has.sepsis&!eicu.has.shock][[x]]))
eicu.preshock.data = parLapply(cluster, 1:sum(eicu.has.shock), function(x) eval.table.with.sofa(eicu.preshock.data.sampling.rate[[x]]$timestamps,eicu.clinical.data[lengths>0][eicu.has.shock][[x]]))
toc()
stopCluster(cluster)

save(eicu.sepsis.labels,eicu.has.sepsis,eicu.shock.labels,eicu.has.shock,eicu.shock.onsets,
    eicu.nonsepsis.data.sampling.rate,eicu.nonshock.data.sampling.rate,eicu.preshock.data.sampling.rate,
    eicu.nonsepsis.data,eicu.nonshock.data,eicu.preshock.data,
    file="eicu.reference.rdata")
rm(list=ls())

library(pracma)
library(tictoc)
library(glmnet)
library(ROCR)
library(matrixStats)
library(parallel)
library(ggplot2)
library(lubridate)
library(xgboost)

source("src/R/functions/mimic/generate_sampling_rate_table.R")
source("src/R/functions/mimic/eval_carry_forward.R")
source("src/R/functions/mimic/eval_interval.R")
source("src/R/functions/mimic/eval_max_in_past_2.R")
source("src/R/functions/mimic/eval_sum_in_past.R")
source("src/R/functions/mimic/eval_early_prediction_timestamps_combined_rf.R")
source("src/R/functions/mimic/eval_table_with_sofa_2.R")
source("src/R/functions/mimic/generate_table_with_sofa_timestamps_2.R")

sofa.scores = readRDS("data/mimic/sofa_scores.rds")
clinical.data = readRDS("data/mimic/clinical.data.mimic.rds")
infection.icustays = readRDS("data/mimic/icd9.infection.icustays.rds")
icustays = readRDS("data/mimic/icustays.rds")

# Convert timestamps to numeric
clinical.subjects = sapply(clinical.data, function(x) x$icustay.id)
clinical.hadm.ids = sapply(clinical.subjects, function(x) icustays$hadm_id[which(icustays$icustay_id==x)])
has.infection = is.element(clinical.subjects, infection.icustays)

lengths = sapply(sofa.scores, function(x) length(x$timestamps))
sepsis.labels = sapply(sofa.scores[lengths>0&has.infection], function(x) rowSums(x[2:7])>=2)
has.sepsis = sapply(sepsis.labels, any)

shock.labels = mapply(function(x,y) x&y$lactate&y$vasopressors, sepsis.labels, sofa.scores[lengths>0&has.infection])
has.shock = sapply(shock.labels, function(x) any(x,na.rm=T))

shock.onsets = as_datetime(mapply(function(x,y) min(x$timestamps[y],na.rm=T),sofa.scores[lengths>0&has.infection][has.shock],shock.labels[has.shock]),tz="GMT")

tic("Generating sampling rate data")
sampling.rate.data = lapply(clinical.data, generate.sampling.rate.table)
toc()

num.cores = detectCores()
cluster = makeCluster(num.cores)
clusterExport(cluster,c("eval.table.with.sofa","eval.carry.forward","eval.sum.in.past","eval.max.in.past","eval.interval","generate.table.with.sofa.timestamps","sofa.scores","sampling.rate.data","shock.onsets","lengths","has.sepsis","has.shock","has.infection"))
clusterEvalQ(cluster,library(lubridate))
tic("Generate data tables (parallel)")
noninfection.data.sampling.rate = parLapply(cluster, 1:sum(!has.infection), function(x) generate.table.with.sofa.timestamps(min(sofa.scores[lengths>0&!has.infection][[x]]$timestamps),max(sofa.scores[lengths>0&!has.infection][[x]]$timestamps),100,sampling.rate.data[lengths>0&!has.infection][[x]]))
nonsepsis.data.sampling.rate = parLapply(cluster, 1:sum(!has.sepsis), function(x) generate.table.with.sofa.timestamps(min(sofa.scores[lengths>0&has.infection][!has.sepsis][[x]]$timestamps),max(sofa.scores[lengths>0&has.infection][!has.sepsis][[x]]$timestamps),100,sampling.rate.data[lengths>0&has.infection][!has.sepsis][[x]]))
nonshock.data.sampling.rate = parLapply(cluster, 1:sum(has.sepsis&!has.shock), function(x) generate.table.with.sofa.timestamps(min(sofa.scores[lengths>0&has.infection][has.sepsis&!has.shock][[x]]$timestamps),max(sofa.scores[lengths>0&has.infection][has.sepsis&!has.shock][[x]]$timestamps),100,sampling.rate.data[lengths>0&has.infection][has.sepsis&!has.shock][[x]]))
preshock.data.sampling.rate = parLapply(cluster, 1:sum(has.shock), function(x) generate.table.with.sofa.timestamps(shock.onsets[x]-minutes(120),shock.onsets[x]-minutes(60),100,sampling.rate.data[lengths>0&has.infection][has.shock][[x]]))
toc()
stopCluster(cluster)

num.cores = detectCores()
cluster = makeCluster(num.cores)
clusterExport(cluster,c("eval.table.with.sofa","eval.carry.forward","eval.sum.in.past","eval.max.in.past","eval.interval","generate.table.with.sofa.timestamps","sofa.scores","clinical.data","shock.onsets","lengths","has.sepsis","has.shock","noninfection.data.sampling.rate","nonsepsis.data.sampling.rate","nonshock.data.sampling.rate","preshock.data.sampling.rate","has.infection"))
clusterEvalQ(cluster,library(lubridate))
tic("Data tables (parallel)")
noninfection.data = parLapply(cluster, 1:sum(!has.infection), function(x) eval.table.with.sofa(noninfection.data.sampling.rate[[x]]$timestamps,clinical.data[lengths>0&!has.infection][[x]]))
nonsepsis.data = parLapply(cluster, 1:sum(!has.sepsis), function(x) eval.table.with.sofa(nonsepsis.data.sampling.rate[[x]]$timestamps,clinical.data[lengths>0&has.infection][!has.sepsis][[x]]))
nonshock.data = parLapply(cluster, 1:sum(has.sepsis&!has.shock), function(x) eval.table.with.sofa(nonshock.data.sampling.rate[[x]]$timestamps,clinical.data[lengths>0&has.infection][has.sepsis&!has.shock][[x]]))
preshock.data = parLapply(cluster, 1:sum(has.shock), function(x) eval.table.with.sofa(preshock.data.sampling.rate[[x]]$timestamps,clinical.data[lengths>0&has.infection][has.shock][[x]]))
toc()
stopCluster(cluster)

save(clinical.subjects,clinical.hadm.ids,has.infection,sepsis.labels,has.sepsis,shock.labels,has.shock,shock.onsets,sampling.rate.data,noninfection.data.sampling.rate,nonsepsis.data.sampling.rate,
    nonshock.data.sampling.rate,preshock.data.sampling.rate,noninfection.data,nonsepsis.data,nonshock.data,preshock.data,
    file="data/mimic/mimic3.reference.data2.rdata")

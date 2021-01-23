rm(list=ls())

library(parallel)
library(lubridate)
library(pracma)
library(abind)

source("src/R/functions/generate_sampling_rate_table.R")
source("src/R/functions/eval_carry_forward.R")
source("src/R/functions/eval_interval.R")
source("src/R/functions/eval_max_in_past_2.R")
source("src/R/functions/eval_sum_in_past.R")
source("src/R/functions/eval_early_prediction_timestamps_glm.R")
source("src/R/functions/eval_early_prediction_timestamps_history.R")
source("src/R/functions/eval_table_with_sofa_4.R")
source("src/R/functions/eval_table_with_sofa_timestamps_history.R")
source("src/R/functions/generate_table_with_sofa_timestamps_history_2.R")

# Compare infection criteria across GLM/Cox on MIMIC-3
is.adult = readRDS("data/mimic/is.adult.rds")
has.matched = readRDS("data/mimic/has.matched.rds")
icd9.infection.icustays = readRDS("data/mimic/icd9.infection.icustays.rds")
icd9.infection.subjects = readRDS("data/mimic/icd9.infection.subjects.rds")
load("data/mimic/infection.antibiotics.cultures.rdata")

sofa.scores = readRDS("data/mimic/sofa_scores.rds")
clinical.data = readRDS("data/mimic/clinical.data.mimic.rds")
icustays = readRDS("data/mimic/icustays.rds")

clinical.icustay.ids = sapply(clinical.data, function(x) x$icustay.id)
clinical.subject.ids = sapply(clinical.icustay.ids,function(x) icustays$subject_id[which(icustays$icustay_id==x)])

has.infection.icd9 = is.element(clinical.icustay.ids, icd9.infection.icustays)
has.infection.abx = is.element(clinical.icustay.ids, infection.abx.icustays)
has.infection.cultures = is.element(clinical.icustay.ids, infection.culture.icustays)

###
# Concomitant
# Generate labels
has.infection = has.infection.abx&has.infection.cultures&is.adult#&has.matched
sepsis.labels = sapply(sofa.scores[has.infection], function(x) rowSums(x[2:7])>=2)
has.sepsis = sapply(sepsis.labels, any)

shock.labels = mapply(function(x,y) x&y$lactate&y$vasopressors, sepsis.labels, sofa.scores[has.infection])
has.shock = sapply(shock.labels, function(x) any(x,na.rm=T))
shock.onsets = as_datetime(mapply(function(x,y) min(x$timestamps[y],na.rm=T),sofa.scores[has.infection][has.shock],shock.labels[has.shock]),tz="GMT")

# Generate training data 
num.cores = 4
cluster = makeCluster(num.cores)
clusterExport(cluster,c("generate.table.with.sofa.timestamps.history","eval.table.with.sofa.timestamps.history","eval.carry.forward","eval.sum.in.past","eval.max.in.past","eval.interval","generate.table.with.sofa.timestamps.history","sofa.scores","clinical.data","shock.onsets","lengths","has.sepsis","has.shock","has.infection"))
clusterEvalQ(cluster,library(lubridate))
tic("Generate data tables (parallel)")
nonsepsis.data = parLapply(cluster, 1:sum(!has.sepsis), function(x) generate.table.with.sofa.timestamps.history(min(sofa.scores[has.infection][!has.sepsis][[x]]$timestamps),max(sofa.scores[has.infection][!has.sepsis][[x]]$timestamps),10,clinical.data[has.infection][!has.sepsis][[x]],hours(1),12))
nonshock.data = parLapply(cluster, 1:sum(has.sepsis&!has.shock), function(x) generate.table.with.sofa.timestamps.history(min(sofa.scores[has.infection][has.sepsis&!has.shock][[x]]$timestamps),max(sofa.scores[has.infection][has.sepsis&!has.shock][[x]]$timestamps),10,clinical.data[has.infection][has.sepsis&!has.shock][[x]],hours(1),12))
preshock.data = parLapply(cluster, 1:sum(has.shock), function(x) generate.table.with.sofa.timestamps.history(min(sofa.scores[has.infection][has.shock][[x]]$timestamps),shock.onsets[x]-minutes(60),10,clinical.data[has.infection][has.shock][[x]],hours(1),12))
toc()
stopCluster(cluster)

save(nonsepsis.data, nonshock.data, preshock.data, file="lstm.reference.dataset.rdata")
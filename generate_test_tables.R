rm(list=ls())

library(parallel)
library(glmnet)
library(survival)
library(ROCR)
library(lubridate)
library(pracma)

source("functions/generate_sampling_rate_table.R")
source("functions/eval_carry_forward.R")
source("functions/eval_interval.R")
source("functions/eval_max_in_past_2.R")
source("functions/eval_sum_in_past.R")
source("functions/eval_early_prediction_timestamps_glm.R")
source("functions/eval_table_with_sofa_2.R")
source("functions/eval_table_with_sofa_timestamps_history.R")


# Compare infection criteria across GLM/Cox on MIMIC-3
is.adult = readRDS("is.adult.rds")
has.matched = readRDS("has.matched.rds")
icd9.infection.icustays = readRDS("icd9.infection.icustays.rds")
icd9.infection.subjects = readRDS("icd9.infection.subjects.rds")
load("infection.antibiotics.cultures.rdata")

sofa.scores = readRDS("processed/sofa_scores.rds")
clinical.data = readRDS("clinical.data.mimic.rds")
icustays = readRDS("icustays.rds")

clinical.icustay.ids = sapply(clinical.data, function(x) x$icustay.id)
clinical.subject.ids = sapply(clinical.icustay.ids,function(x) icustays$subject_id[which(icustays$icustay_id==x)])

has.infection.icd9 = is.element(clinical.icustay.ids, icd9.infection.icustays)
has.infection.abx = is.element(clinical.icustay.ids, infection.abx.icustays)
has.infection.cultures = is.element(clinical.icustay.ids, infection.culture.icustays)

###
# Concomitant
# Generate labels
has.infection = has.infection.abx&has.infection.cultures&is.adult
sepsis.labels = sapply(sofa.scores[has.infection], function(x) rowSums(x[2:7])>=2)
has.sepsis = sapply(sepsis.labels, any)

shock.labels = mapply(function(x,y) x&y$lactate&y$vasopressors, sepsis.labels, sofa.scores[has.infection])
has.shock = sapply(shock.labels, function(x) any(x,na.rm=T))
shock.onsets = as_datetime(mapply(function(x,y) min(x$timestamps[y],na.rm=T),sofa.scores[has.infection][has.shock],shock.labels[has.shock]),tz="GMT")

# Generate training data 

num.cores = detectCores()
cluster = makeCluster(num.cores)
clusterExport(cluster,c("eval.table.with.sofa","eval.carry.forward","eval.sum.in.past","eval.max.in.past","eval.interval","sofa.scores","clinical.data","shock.onsets","lengths","has.sepsis","has.shock","has.infection"))
clusterEvalQ(cluster,library(lubridate))
tic("Generate data tables (parallel)")
nonsepsis.data = parLapply(cluster, 1:sum(!has.sepsis), function(x) eval.table.with.sofa(sofa.scores[has.infection][!has.sepsis][[x]]$timestamps,clinical.data[has.infection][!has.sepsis][[x]]))
nonshock.data = parLapply(cluster, 1:sum(has.sepsis&!has.shock), function(x) eval.table.with.sofa(sofa.scores[has.infection][has.sepsis&!has.shock][[x]]$timestamps,clinical.data[has.infection][has.sepsis&!has.shock][[x]]))
preshock.data = parLapply(cluster, 1:sum(has.shock), function(x) eval.table.with.sofa(sofa.scores[has.infection][has.shock][[x]]$timestamps[sofa.scores[has.infection][has.shock][[x]]$timestamps<=shock.onsets[x]],clinical.data[has.infection][has.shock][[x]]))
toc()
stopCluster(cluster)

save(nonsepsis.data,nonshock.data,preshock.data,file="test.tables.concomitant.rdata")

###
# LSTM - Concomitant
# Generate training data 
num.cores = 4
cluster = makeCluster(num.cores)
clusterExport(cluster,c("eval.table.with.sofa.timestamps.history","eval.carry.forward","eval.sum.in.past","eval.max.in.past","eval.interval","sofa.scores","clinical.data","shock.onsets","lengths","has.sepsis","has.shock","has.infection"))
clusterEvalQ(cluster,library(lubridate))
tic("Generate data tables (parallel)")
nonsepsis.data = parLapply(cluster, 1:sum(!has.sepsis), function(x) eval.table.with.sofa.timestamps.history(sofa.scores[has.infection][!has.sepsis][[x]]$timestamps,clinical.data[has.infection][!has.sepsis][[x]],hours(1),12))
nonshock.data = parLapply(cluster, 1:sum(has.sepsis&!has.shock), function(x) eval.table.with.sofa.timestamps.history(sofa.scores[has.infection][has.sepsis&!has.shock][[x]]$timestamps,clinical.data[has.infection][has.sepsis&!has.shock][[x]],hours(1),12))
preshock.data = parLapply(cluster, 1:sum(has.shock), function(x) eval.table.with.sofa.timestamps.history(sofa.scores[has.infection][has.shock][[x]]$timestamps[sofa.scores[has.infection][has.shock][[x]]$timestamps<=shock.onsets[x]],clinical.data[has.infection][has.shock][[x]],hours(1),12))
toc()
stopCluster(cluster)

save(nonsepsis.data,nonshock.data,preshock.data,file="test.tables.concomitant.lstm.rdata")

###
# ICD9
has.infection = has.infection.icd9&is.adult
sepsis.labels = sapply(sofa.scores[has.infection], function(x) rowSums(x[2:7])>=2)
has.sepsis = sapply(sepsis.labels, any)

shock.labels = mapply(function(x,y) x&y$lactate&y$vasopressors, sepsis.labels, sofa.scores[has.infection])
has.shock = sapply(shock.labels, function(x) any(x,na.rm=T))
shock.onsets = as_datetime(mapply(function(x,y) min(x$timestamps[y],na.rm=T),sofa.scores[has.infection][has.shock],shock.labels[has.shock]),tz="GMT")

# Generate training data 

num.cores = detectCores()
cluster = makeCluster(num.cores)
clusterExport(cluster,c("eval.table.with.sofa","eval.carry.forward","eval.sum.in.past","eval.max.in.past","eval.interval","sofa.scores","clinical.data","shock.onsets","lengths","has.sepsis","has.shock","has.infection"))
clusterEvalQ(cluster,library(lubridate))
tic("Generate data tables (parallel)")
nonsepsis.data = parLapply(cluster, 1:sum(!has.sepsis), function(x) eval.table.with.sofa(sofa.scores[has.infection][!has.sepsis][[x]]$timestamps,clinical.data[has.infection][!has.sepsis][[x]]))
nonshock.data = parLapply(cluster, 1:sum(has.sepsis&!has.shock), function(x) eval.table.with.sofa(sofa.scores[has.infection][has.sepsis&!has.shock][[x]]$timestamps,clinical.data[has.infection][has.sepsis&!has.shock][[x]]))
preshock.data = parLapply(cluster, 1:sum(has.shock), function(x) eval.table.with.sofa(sofa.scores[has.infection][has.shock][[x]]$timestamps[sofa.scores[has.infection][has.shock][[x]]$timestamps<=shock.onsets[x]],clinical.data[has.infection][has.shock][[x]]))
toc()
stopCluster(cluster)

save(nonsepsis.data,nonshock.data,preshock.data,file="test.tables.icd9.rdata")

###
# LSTM - ICD9
# Generate training data 
num.cores = 4
cluster = makeCluster(num.cores)
clusterExport(cluster,c("eval.table.with.sofa.timestamps.history","eval.carry.forward","eval.sum.in.past","eval.max.in.past","eval.interval","sofa.scores","clinical.data","shock.onsets","lengths","has.sepsis","has.shock","has.infection"))
clusterEvalQ(cluster,library(lubridate))
tic("Generate data tables (parallel)")
nonsepsis.data = parLapply(cluster, 1:sum(!has.sepsis), function(x) eval.table.with.sofa.timestamps.history(sofa.scores[has.infection][!has.sepsis][[x]]$timestamps,clinical.data[has.infection][!has.sepsis][[x]],hours(1),12))
nonshock.data = parLapply(cluster, 1:sum(has.sepsis&!has.shock), function(x) eval.table.with.sofa.timestamps.history(sofa.scores[has.infection][has.sepsis&!has.shock][[x]]$timestamps,clinical.data[has.infection][has.sepsis&!has.shock][[x]],hours(1),12))
preshock.data = parLapply(cluster, 1:sum(has.shock), function(x) eval.table.with.sofa.timestamps.history(sofa.scores[has.infection][has.shock][[x]]$timestamps[sofa.scores[has.infection][has.shock][[x]]$timestamps<=shock.onsets[x]],clinical.data[has.infection][has.shock][[x]],hours(1),12))
toc()
stopCluster(cluster)

save(nonsepsis.data,nonshock.data,preshock.data,file="test.tables.icd9.lstm.rdata")
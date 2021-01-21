rm(list=ls())
library(lubridate)

admission.data.rds = readRDS("data/mimic/admission.data.rds")
clinical.data = readRDS("data/mimic/clinical.data.mimic.rds")
sofa.scores = readRDS("data/mimic/processed/sofa_scores.rds")
icustays = readRDS("data/mimic/icustays.rds")

clinical.subjects = sapply(clinical.data, function(x) icustays$subject_id[which(icustays$icustay_id==x$icustay.id)])

dobs = as_datetime(sapply(clinical.subjects, function(x) patient.data$dob[which(patient.data$subject_id==x)]),tz="GMT")
ages = mapply(function(a,b) as.duration(a$timestamps[1]-b)/dyears(1), sofa.scores, dobs)

is.adult = ages>=18
saveRDS(is.adult,"data/mimic/is.adult.rds")
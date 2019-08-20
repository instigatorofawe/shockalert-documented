rm(list=ls())

library(RPostgreSQL)
library(pracma)
library(tictoc)
library(lubridate)

user = "postgres"
password = "postgres"
db = "mimic"

query = "select * from patients"

tic()
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
patient.data = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

saveRDS(patient.data,"patient.data.rds")

admission.data.rds = readRDS("admission.data.rds")
clinical.data = readRDS("clinical.data.mimic.rds")
sofa.scores = readRDS("processed/sofa_scores.rds")
icustays = readRDS("icustays.rds")

clinical.subjects = sapply(clinical.data, function(x) icustays$subject_id[which(icustays$icustay_id==x$icustay.id)])

dobs = as_datetime(sapply(clinical.subjects, function(x) patient.data$dob[which(patient.data$subject_id==x)]),tz="GMT")
ages = mapply(function(a,b) as.duration(a$timestamps[1]-b)/dyears(1), sofa.scores, dobs)

is.adult = ages>=18
saveRDS(is.adult,"is.adult.rds")
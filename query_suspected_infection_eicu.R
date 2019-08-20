rm(list=ls())

library(RPostgreSQL)
library(tictoc)
library(parallel)

user = "postgres"
password = "postgres"
db = "eicu"

# ICD-9 codes
query = "select patientunitstayid, icd9code from diagnosis"
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
result = dbGetQuery(connection, query)
dbDisconnect(connection)

cl = makeCluster(detectCores())
tic()
processed.icd9.codes = parSapply(cl, result$icd9code, function(x) na.omit(as.numeric(trimws(strsplit(x,",")[[1]]))))
toc()
stopCluster(cl)

subjects = unique(result$patientunitstayid)

cl = makeCluster(detectCores())
clusterExport(cl, c("processed.icd9.codes","result"))
tic()
codes = parSapply(cl, subjects, function(x) unique(unlist(processed.icd9.codes[result$patientunitstayid==x])))
toc()
stopCluster(cl)

save(subjects,codes,processed.icd9.codes,result,file="eicu/diagnosis_query.rdata")

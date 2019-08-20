rm(list=ls())

library(RPostgreSQL)
library(pracma)
library(tictoc)

user = "postgres"
password = "postgres"
db = "mimic"

query = "select * from admissions"

Sys.setenv(TZ="GMT")

tic()
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
admission.data = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

saveRDS(admission.data,file="admission.data.rds")
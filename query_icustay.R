rm(list=ls())

library(RPostgreSQL)
library(pracma)
library(tictoc)

user = "postgres"
password = "postgres"
db = "mimic"

query = "select * from icustays"

tic()
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
icustay.data = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

saveRDS(icustay.data, file="icustays.rds")
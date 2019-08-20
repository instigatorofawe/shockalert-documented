rm(list=ls())

library(RPostgreSQL)
library(pracma)
library(tictoc)

user = "postgres"
password = "postgres"
db = "mimic"

query = "SELECT * FROM diagnoses_icd"

tic()
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
icd9.data = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

saveRDS(icd9.data,"icd9.rds")
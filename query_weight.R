rm(list=ls())

library(RPostgreSQL)
library(pracma)
library(tictoc)

user = "postgres"
password = "postgres"
db = "mimic"

query = "select * from chartevents where itemid in (580,581,763,3580,3581,3582,3583,3693,224639,226512,226531)"

Sys.setenv(TZ="GMT")

tic()
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
weight.data = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

weight.data = weight.data[weight.data$valueuom=="kg",]

saveRDS(weight.data,file="weight.data.rds")
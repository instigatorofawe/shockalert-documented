rm(list=ls())

library(RPostgreSQL)
library(pracma)
library(tictoc)

user = "postgres"
password = "postgres"
db = "mimic"

epi.items = c(3112, 5752, 30119, 30309, 30044, 221289)
dop.items = c(4501, 5329, 30043, 30307, 221662)
dob.items = c(5747, 30306, 30042, 221653)
norepi.items = c(221906, 30047, 30120)
phen.items = c(5656, 6752, 6090, 221749, 30127, 30128)
vasopressin.items = c(4501, 5329, 30043, 30307, 221662)

vasopressor.items = c(epi.items,dop.items,dob.items,norepi.items,phen.items,vasopressin.items)

query = "SELECT * FROM inputevents_cv"

Sys.setenv(TZ="GMT")

tic()
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
input.data.cv = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

#query = sprintf("SELECT * FROM inputevents_mv",paste(vasopressor.items,collapse=","))
query = "SELECT * FROM inputevents_mv"

tic()
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
input.data.mv = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

save(input.data.cv,input.data.mv,file="input.data.rdata")


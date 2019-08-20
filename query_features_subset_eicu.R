rm(list=ls())

library(RPostgreSQL)
library(pracma)
library(tictoc)

user = "postgres"
password = "postgres"
db = "eicu"

load("eicu/diagnosis_query.rdata")
has.infection.icd9 = readRDS("eicu/has_infection_icd9.rds")
sampled.patientunitstayid = subjects[has.infection.icd9]

clinical.data = vector(mode = "list", length = length(sampled.patientunitstayid))

# GCS: query physicalExam
query = paste("select * from physicalexam where physicalexampath like '%GCS%' and patientunitstayid in (", paste(sampled.patientunitstayid,collapse=",") ,")",sep="")
tic("GCS query")
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
gcs.result = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

# Lactate: lab
query = paste("select * from lab where labname = 'lactate' and patientunitstayid in (", paste(sampled.patientunitstayid,collapse=",") ,")",sep="")
tic("Lactate query")
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
lactate.result = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

# PaO2: lab
query = paste("select * from lab where labname = 'paO2' and patientunitstayid in (", paste(sampled.patientunitstayid,collapse=",") ,")",sep="")
tic("PaO2 query")
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
pao2.result = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

# Platelets: lab
query = paste("select * from lab where labname = 'platelets x 1000' and patientunitstayid in (", paste(sampled.patientunitstayid,collapse=",") ,")",sep="")
tic("PaO2 query")
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
platelets.result = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

# Bilirubin
query = paste("select * from lab where labname = 'direct bilirubin' and patientunitstayid in (", paste(sampled.patientunitstayid,collapse=",") ,")",sep="")
tic("Bilirubin query")
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
bili.result = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

# Creatinine
query = paste("select * from lab where labname = 'creatinine' and patientunitstayid in (", paste(sampled.patientunitstayid,collapse=",") ,")",sep="")
tic("Creatinine query")
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
creat.result = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

# FiO2
query = paste("select * from respiratorycharting where patientunitstayid in (", paste(sampled.patientunitstayid,collapse=",") ,") and (respchartvaluelabel = 'FiO2' or respchartvaluelabel = 'FIO2 (%)')",sep="")
tic("FiO2 query")
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
fio2.result = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()
# Remove non-numeric symbols from FiO2 result
fio2.result$respchartvalue = as.numeric(gsub("[^.0-9]","",fio2.result$respchartvalue))
# Throw out non-physical values
fio2.result = fio2.result[fio2.result$respchartvalue<=100&fio2.result$respchartvalue>=21,]

# Ventilation
query = paste("select * from respiratorycare where patientunitstayid in (", paste(sampled.patientunitstayid,collapse=",") ,")",sep="")
tic("Ventilation query")
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
vent.result = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

# MAP
query = paste("select * from nursecharting where patientunitstayid in (", paste(sampled.patientunitstayid,collapse=","),") and (nursingchartcelltypevallabel = 'MAP (mmHg)' or nursingchartcelltypevalname = 'Non-Invasive BP Mean' or nursingchartcelltypevalname = 'Invasive BP Mean')",sep="")
tic("MAP query")
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
map.result = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()
# Remove non-numeric symbols
map.result$nursingchartvalue = as.numeric(map.result$nursingchartvalue)

# Vasopressors
dop.query = paste("select * from infusiondrug where drugname like '%Dopamine%' and patientunitstayid in (", paste(sampled.patientunitstayid,collapse=",") ,")",sep="")
dob.query = paste("select * from infusiondrug where drugname like '%Dobutamine%' and patientunitstayid in (", paste(sampled.patientunitstayid,collapse=",") ,")",sep="")
ep.query = paste("select * from infusiondrug where drugname like '%Epinephrine%' and patientunitstayid in (", paste(sampled.patientunitstayid,collapse=",") ,")",sep="")
norep.query = paste("select * from infusiondrug where drugname like '%Norepinephrine%' and patientunitstayid in (", paste(sampled.patientunitstayid,collapse=",") ,")",sep="")

tic("Vasopressor query")
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
dop.result = dbGetQuery(connection, dop.query)
dob.result = dbGetQuery(connection, dob.query)
ep.result = dbGetQuery(connection, ep.query)
norep.result = dbGetQuery(connection, norep.query)
dbDisconnect(connection)
toc()

dop.result$drugrate = as.numeric(dop.result$drugrate)
dop.result$drugrate[is.na(dop.result$drugrate)] = 1

dob.result$drugrate = as.numeric(dob.result$drugrate)
dob.result$drugrate[is.na(dob.result$drugrate)] = 1

ep.result$drugrate = as.numeric(ep.result$drugrate)
ep.result$drugrate[is.na(ep.result$drugrate)] = 1

norep.result$drugrate = as.numeric(norep.result$drugrate)
norep.result$drugrate[is.na(norep.result$drugrate)] = 1


# Urine output
query = paste("select * from intakeoutput where celllabel like '%Urin%' and patientunitstayid in (", paste(sampled.patientunitstayid,collapse=",") ,")",sep="")
tic("Urine query")
connection = dbConnect(PostgreSQL(), user=user, password=password, dbname=db)
urine.result = dbGetQuery(connection, query)
dbDisconnect(connection)
toc()

increment = 100

tic("Processing clinical data")
for (i in 1:length(clinical.data)) {
    if (i %% increment == 0) {
        fprintf("Processing %d of %d...\n",i,length(clinical.data))
    }

    # Calculate GCS
    gcs = NULL
    gcs.entries = gcs.result[gcs.result$patientunitstayid==sampled.patientunitstayid[i],]
    if (dim(gcs.entries)[1]>0) {
        is.component = grepl("Verbal",gcs.entries$physicalexampath)|grepl("Motor",gcs.entries$physicalexampath)|grepl("Eyes",gcs.entries$physicalexampath)
        gcs.timestamps = sort(unique(gcs.entries$physicalexamoffset[is.component]))
        gcs.values = sapply(gcs.timestamps,function(x) sum(as.numeric(gcs.entries$physicalexamvalue[gcs.entries$physicalexamoffset==x&is.component])))
        gcs = list(timestamps=gcs.timestamps,values=gcs.values)
    }

    # Calculate platelets
    platelets = NULL
    platelets.entries = platelets.result[platelets.result$patientunitstayid==sampled.patientunitstayid[i],]
    if (dim(platelets.entries)[1]>0) {
        platelets.timestamps = sort(unique(platelets.entries$labresultoffset))
        platelets.values = sapply(platelets.timestamps,function(x) platelets.entries$labresult[platelets.entries$labresultoffset==x])
        platelets = list(timestamps=platelets.timestamps,values=platelets.values)
    }

    # Calculate lactate
    lactate = NULL
    lactate.entries = lactate.result[lactate.result$patientunitstayid==sampled.patientunitstayid[i],]
    if (dim(lactate.entries)[1]>0) {
        lactate.timestamps = sort(unique(lactate.entries$labresultoffset))
        lactate.values = sapply(lactate.timestamps,function(x) lactate.entries$labresult[lactate.entries$labresultoffset==x])
        lactate = list(timestamps=lactate.timestamps,values=lactate.values)
    }

    # Calculate PaO2
    pao2 = NULL
    pao2.entries = pao2.result[pao2.result$patientunitstayid==sampled.patientunitstayid[i],]
    if (dim(pao2.entries)[1]>0) {
        pao2.timestamps = sort(unique(pao2.entries$labresultoffset))
        pao2.values = sapply(pao2.timestamps,function(x) pao2.entries$labresult[pao2.entries$labresultoffset==x])
        pao2 = list(timestamps=pao2.timestamps,values=pao2.values)
    }

    # Calculate Bilirubin
    bili = NULL
    bili.entries = bili.result[bili.result$patientunitstayid==sampled.patientunitstayid[i],]
    if (dim(bili.entries)[1]>0) {
        bili.timestamps = sort(unique(bili.entries$labresultoffset))
        bili.values = sapply(bili.timestamps,function(x) bili.entries$labresult[bili.entries$labresultoffset==x])
        bili = list(timestamps=bili.timestamps,values=bili.values)
    }

    # Calculate Creatinine
    creat = NULL
    creat.entries = creat.result[creat.result$patientunitstayid==sampled.patientunitstayid[i],]
    if (dim(creat.entries)[1]>0) {
        creat.timestamps = sort(unique(creat.entries$labresultoffset))
        creat.values = sapply(creat.timestamps,function(x) creat.entries$labresult[creat.entries$labresultoffset==x])
        creat = list(timestamps=creat.timestamps,values=creat.values)
    }

    # Calculate FiO2
    fio2 = NULL
    fio2.entries = fio2.result[fio2.result$patientunitstayid==sampled.patientunitstayid[i],]
    if (dim(fio2.entries)[1]>0) {
        fio2.timestamps = sort(unique(fio2.entries$respchartoffset))
        fio2.values = sapply(fio2.timestamps,function(x) fio2.entries$respchartvalue[fio2.entries$respchartoffset==x])
        fio2 = list(timestamps=fio2.timestamps,values=fio2.values)
    }

    # Calculate MAP
    map = NULL
    map.entries = map.result[map.result$patientunitstayid==sampled.patientunitstayid[i],]
    if (dim(map.entries)[1]>0) {
        map.timestamps = sort(unique(map.entries$nursingchartoffset))
        map.values = sapply(map.timestamps, function(x) mean(map.entries$nursingchartvalue[map.entries$nursingchartoffset==x]))
        map = list(timestamps=map.timestamps, values=map.values)
    }

    # Calculate ventilation intervals - what to do about starts with no stop time?
    vent = NULL
    vent.entries = vent.result[vent.result$patientunitstayid==sampled.patientunitstayid[i],]
    if (dim(vent.entries)[1]>0) {
        vent.starts = sort(unique(vent.entries$ventstartoffset[vent.entries$ventstartoffset!=0]))
        vent.stops = sort(unique(vent.entries$priorventendoffset[vent.entries$priorventendoffset!=0]))
        vent = list(starts=vent.starts,stops=vent.stops)
    }

    # Calculate vasopressors
    # Database is not consistent when it comes to units
    dop = NULL
    dob = NULL
    ep = NULL
    norep = NULL

    dop.entries = dop.result[dop.result$patientunitstayid==sampled.patientunitstayid[i],]
    dob.entries = dob.result[dob.result$patientunitstayid==sampled.patientunitstayid[i],]
    ep.entries = ep.result[ep.result$patientunitstayid==sampled.patientunitstayid[i],]
    norep.entries = norep.result[norep.result$patientunitstayid==sampled.patientunitstayid[i],]

    if (dim(dop.entries)[1]>0) {
        dop.timestamps = sort(unique(dop.entries$infusionoffset))
        dop.values = sapply(dop.timestamps,function(x) dop.entries$drugrate[dop.entries$infusionoffset==x])
        dop = list(timestamps=dop.timestamps, values = dop.values)
    }

    if (dim(dob.entries)[1]>0) {
        dob.timestamps = sort(unique(dob.entries$infusionoffset))
        dob.values = sapply(dob.timestamps,function(x) dob.entries$drugrate[dob.entries$infusionoffset==x])
        dob = list(timestamps=dob.timestamps, values = dob.values)
    }

    if (dim(ep.entries)[1]>0) {
        ep.timestamps = sort(unique(ep.entries$infusionoffset))
        ep.values = sapply(ep.timestamps,function(x) ep.entries$drugrate[ep.entries$infusionoffset==x])
        ep = list(timestamps=ep.timestamps, values = ep.values)
    }

    if (dim(norep.entries)[1]>0) {
        norep.timestamps = sort(unique(norep.entries$infusionoffset))
        norep.values = sapply(norep.timestamps,function(x) norep.entries$drugrate[norep.entries$infusionoffset==x])
        norep = list(timestamps=norep.timestamps, values = norep.values)
    }

    # Calculate urine output
    urine = NULL
    urine.entries = urine.result[urine.result$patientunitstayid==sampled.patientunitstayid[i],]
    if (dim(urine.entries)[1]>0) {
        urine.timestamps = sort(unique(urine.entries$intakeoutputoffset))
        urine.values = sapply(urine.timestamps, function(x) urine.entries$cellvaluenumeric[urine.entries$intakeoutputoffset==x])
        urine = list(timestamps=urine.timestamps,values=urine.values)
    }


    clinical.data[[i]] = list(subject.id=sampled.patientunitstayid[i],gcs=gcs,platelets=platelets,lactate=lactate,pao2=pao2,bili=bili,creat=creat,fio2=fio2,map=map,vent=vent,dop=dop,dob=dob,ep=ep,norep=norep,urine=urine)

}
toc()

saveRDS(clinical.data,file="eicu/clinical_data.rds")

has.gcs = sapply(clinical.data,function(x) !is.null(x$gcs))
has.platelets = sapply(clinical.data,function(x) !is.null(x$platelets))
has.lactate = sapply(clinical.data,function(x) !is.null(x$lactate))
has.pao2 = sapply(clinical.data,function(x) !is.null(x$pao2))
has.bili = sapply(clinical.data,function(x) !is.null(x$bili))
has.creat = sapply(clinical.data,function(x) !is.null(x$creat))
has.fio2 = sapply(clinical.data,function(x) !is.null(x$fio2))
has.map = sapply(clinical.data,function(x) !is.null(x$map))
has.vent = sapply(clinical.data,function(x) !is.null(x$vent))
has.dop = sapply(clinical.data,function(x) !is.null(x$dop))

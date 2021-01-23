rm(list=ls())

library(RPostgres)
library(pracma)
library(tictoc)

user = "postgres"
password = "postgres"
db = "eicu"

connection = dbConnect(Postgres(), user=user, password=password, dbname=db)

# Query all patient data in general
query = "select * from patient"
tic("Patient data query")
patient.result = dbGetQuery(connection, query)
toc()

load("data/eicu/diagnosis_query.rdata")
has.infection.icd9 = readRDS("data/eicu/has_infection_icd9.rds")
query.subjects = subjects[has.infection.icd9]


# Query features
# HR
query = paste("select * from nursecharting where patientunitstayid in (", paste(query.subjects,collapse=","), ") and nursingchartcelltypevallabel = 'Heart Rate'",sep="")
tic("HR query")
hr.result = dbGetQuery(connection, query)
toc()
# SBP
query = paste("select * from nursecharting where patientunitstayid in (", paste(query.subjects,collapse=","), ") and (nursingchartcelltypevalname = 'Invasive BP Systolic' or nursingchartcelltypevalname = 'Non-Invasive BP Systolic')",sep="")
tic("SBP query")
sbp.result = dbGetQuery(connection, query)
toc()
# DBP
query = paste("select * from nursecharting where patientunitstayid in (", paste(query.subjects,collapse=","), ") and (nursingchartcelltypevalname = 'Invasive BP Diastolic' or nursingchartcelltypevalname = 'Non-Invasive BP Diastolic')",sep="")
tic("DBP query")
dbp.result = dbGetQuery(connection, query)
toc()

# MBP
query = paste("select * from nursecharting where patientunitstayid in (", paste(query.subjects,collapse=","), ") and (nursingchartcelltypevalname = 'Invasive BP Mean' or nursingchartcelltypevalname = 'Non-Invasive BP Mean')",sep="")
tic("MBP query")
mbp.result = dbGetQuery(connection, query)
toc()

# RESP
query = paste("select * from nursecharting where patientunitstayid in (", paste(query.subjects,collapse=","), ") and nursingchartcelltypevallabel = 'Respiratory Rate'",sep="")
tic("RESP query")
resp.result = dbGetQuery(connection, query)
toc()

# Temperature
query = paste("select * from nursecharting where patientunitstayid in (", paste(query.subjects,collapse=","), ") and nursingchartcelltypevalname = 'Temperature (C)'",sep="")
tic("Temperature query")
temp.result = dbGetQuery(connection, query)
toc()

# CVP
query = paste("select * from nursecharting where patientunitstayid in (", paste(query.subjects,collapse=","), ") and nursingchartcelltypevallabel = 'CVP'",sep="")
tic("CVP query")
cvp.result = dbGetQuery(connection, query)
toc()

# PaO2
query = paste("select * from lab where labname = 'paO2' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
tic("HR query")
pao2.result = dbGetQuery(connection, query)
toc()

# FiO2
query = paste("select * from respiratorycharting where patientunitstayid in (", paste(query.subjects,collapse=",") ,") and (respchartvaluelabel = 'FiO2' or respchartvaluelabel = 'FIO2 (%)')",sep="")
tic("FiO2 query")
fio2.result = dbGetQuery(connection, query)
toc()

# GCS
query = paste("select * from physicalexam where physicalexampath like '%GCS%' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
tic("GCS query")
gcs.result = dbGetQuery(connection, query)
toc()

# Bilirubin
query = paste("select * from lab where labname = 'direct bilirubin' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
tic("Bili query")
bili.result = dbGetQuery(connection, query)
toc()

# Platelets
query = paste("select * from lab where labname = 'platelets x 1000' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
tic("Platelets query")
platelets.result = dbGetQuery(connection, query)
toc()

# Creatinine
query = paste("select * from lab where labname = 'creatinine' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
tic("Creatinine query")
creat.result = dbGetQuery(connection, query)
toc()

# Lactate
query = paste("select * from lab where labname = 'lactate' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
tic("Lactate query")
lact.result = dbGetQuery(connection, query)
toc()

# BUN
query = paste("select * from lab where labname = 'BUN' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
tic("BUN query")
bun.result = dbGetQuery(connection, query)
toc()

# Arterial pH
query = paste("select * from lab where labname = 'pH' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
tic("pH query")
ph.result = dbGetQuery(connection, query)
toc()

# WBC
query = paste("select * from lab where labname = 'WBC x 1000' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
tic("WBC query")
wbc.result = dbGetQuery(connection, query)
toc()

# PaCO2
query = paste("select * from lab where labname = 'paCO2' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
tic("PaCO2 query")
paco2.result = dbGetQuery(connection, query)
toc()

# Hemoglobin
query = paste("select * from lab where labname = 'Hgb' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
tic("Hgb query")
hgb.result = dbGetQuery(connection, query)
toc()

# Hematocrit
query = paste("select * from lab where labname = 'Hct' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
tic("Hct query")
hct.result = dbGetQuery(connection, query)
toc()

# Potassium
query = paste("select * from lab where labname = 'potassium' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
tic("Potassium query")
potassium.result = dbGetQuery(connection, query)
toc()

# Urine
query = paste("select * from intakeoutput where celllabel like '%Urin%' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
tic("Urine query")
urine.result = dbGetQuery(connection, query)
toc()

# Vasopressors
tic("Vasopressors query")
dop.query = paste("select * from infusiondrug where drugname like '%Dopamine%' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
dob.query = paste("select * from infusiondrug where drugname like '%Dobutamine%' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
ep.query = paste("select * from infusiondrug where drugname like '%Epinephrine%' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
norep.query = paste("select * from infusiondrug where drugname like '%Norepinephrine%' and patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")

dop.result = dbGetQuery(connection, dop.query)
dob.result = dbGetQuery(connection, dob.query)
ep.result = dbGetQuery(connection, ep.query)
norep.result = dbGetQuery(connection, norep.query)

dop.result$drugrate = as.numeric(dop.result$drugrate)
dop.result$drugrate[is.na(dop.result$drugrate)] = 1

dob.result$drugrate = as.numeric(dob.result$drugrate)
dob.result$drugrate[is.na(dob.result$drugrate)] = 1

ep.result$drugrate = as.numeric(ep.result$drugrate)
ep.result$drugrate[is.na(ep.result$drugrate)] = 1

norep.result$drugrate = as.numeric(norep.result$drugrate)
norep.result$drugrate[is.na(norep.result$drugrate)] = 1
toc()

# Ventilator
tic("Ventilation query")
query = paste("select * from respiratorycare where patientunitstayid in (", paste(query.subjects,collapse=",") ,")",sep="")
vent.result = dbGetQuery(connection, query)
toc()


dbDisconnect(connection)

clinical.data = vector(mode="list",length=length(query.subjects))

tic("Processing clinical data")

increment = 100

for (i in 1:length(clinical.data)) {
    if (i %% increment ==0) {
        fprintf("Processing %d of %d...\n",i,length(clinical.data))
    }

    # 1. HR
    hr = NULL
    hr.entries = hr.result[hr.result$patientunitstayid==query.subjects[i],]
    hr.entries$nursingchartvalue = as.numeric(hr.entries$nursingchartvalue)
    if (dim(hr.entries)[1]>0) {
        hr.timestamps = sort(unique(hr.entries$nursingchartoffset))
        hr.values = sapply(hr.timestamps,function(x) mean(hr.entries$nursingchartvalue[hr.entries$nursingchartoffset==x],na.rm=TRUE))
        hr = list(timestamps=hr.timestamps,values=hr.values)
    }
    # 2. SBP
    sbp = NULL
    sbp.entries = sbp.result[sbp.result$patientunitstayid==query.subjects[i],]
    sbp.entries$nursingchartvalue = as.numeric(sbp.entries$nursingchartvalue)
    if (dim(sbp.entries)[1]>0) {
        sbp.timestamps = sort(unique(sbp.entries$nursingchartoffset))
        sbp.values = sapply(sbp.timestamps,function(x) mean(sbp.entries$nursingchartvalue[sbp.entries$nursingchartoffset==x],na.rm=TRUE))
        sbp = list(timestamps=sbp.timestamps,values=sbp.values)
    }
    # 3. DBP
    dbp = NULL
    dbp.entries = dbp.result[dbp.result$patientunitstayid==query.subjects[i],]
    dbp.entries$nursingchartvalue = as.numeric(dbp.entries$nursingchartvalue)
    if (dim(dbp.entries)[1]>0) {
        dbp.timestamps = sort(unique(dbp.entries$nursingchartoffset))
        dbp.values = sapply(dbp.timestamps,function(x) mean(dbp.entries$nursingchartvalue[dbp.entries$nursingchartoffset==x],na.rm=TRUE))
        dbp = list(timestamps=dbp.timestamps,values=dbp.values)
    }
    # 4. MBP
    mbp = NULL
    mbp.entries = mbp.result[mbp.result$patientunitstayid==query.subjects[i],]
    mbp.entries$nursingchartvalue = as.numeric(mbp.entries$nursingchartvalue)
    if (dim(mbp.entries)[1]>0) {
        mbp.timestamps = sort(unique(mbp.entries$nursingchartoffset))
        mbp.values = sapply(mbp.timestamps,function(x) mean(mbp.entries$nursingchartvalue[mbp.entries$nursingchartoffset==x],na.rm=TRUE))
        mbp = list(timestamps=mbp.timestamps,values=mbp.values)
    }
    # 5. RESP
    resp = NULL
    resp.entries = resp.result[resp.result$patientunitstayid==query.subjects[i],]
    resp.entries$nursingchartvalue = as.numeric(resp.entries$nursingchartvalue)
    if (dim(resp.entries)[1]>0) {
        resp.timestamps = sort(unique(resp.entries$nursingchartoffset))
        resp.values = sapply(resp.timestamps,function(x) mean(resp.entries$nursingchartvalue[resp.entries$nursingchartoffset==x],na.rm=TRUE))
        resp = list(timestamps=resp.timestamps,values=resp.values)
    }
    # 6. Temperature
    temp = NULL
    temp.entries = temp.result[temp.result$patientunitstayid==query.subjects[i],]
    temp.entries$nursingchartvalue = as.numeric(temp.entries$nursingchartvalue)
    if (dim(temp.entries)[1]>0) {
        temp.timestamps = sort(unique(temp.entries$nursingchartoffset))
        temp.values = sapply(temp.timestamps,function(x) mean(temp.entries$nursingchartvalue[temp.entries$nursingchartoffset==x],na.rm=TRUE))
        temp = list(timestamps=temp.timestamps,values=temp.values)
    }
    # 7. CVP
    cvp = NULL
    cvp.entries = cvp.result[cvp.result$patientunitstayid==query.subjects[i],]
    cvp.entries$nursingchartvalue = as.numeric(cvp.entries$nursingchartvalue)
    if (dim(cvp.entries)[1]>0) {
        cvp.timestamps = sort(unique(cvp.entries$nursingchartoffset))
        cvp.values = sapply(cvp.timestamps,function(x) mean(cvp.entries$nursingchartvalue[cvp.entries$nursingchartoffset==x],na.rm=TRUE))
        cvp = list(timestamps=cvp.timestamps,values=cvp.values)
    }
    # 8. PaO2
    pao2 = NULL
    pao2.entries = pao2.result[pao2.result$patientunitstayid==query.subjects[i],]
    pao2.entries$labresult = as.numeric(pao2.entries$labresult)
    if (dim(pao2.entries)[1]>0) {
        pao2.timestamps = sort(unique(pao2.entries$labresultoffset))
        pao2.values = sapply(pao2.timestamps,function(x) mean(pao2.entries$labresult[pao2.entries$labresultoffset==x],na.rm=TRUE))
        pao2 = list(timestamps=pao2.timestamps,values=pao2.values)
    }
    # 9. FiO2
    fio2 = NULL
    fio2.entries = fio2.result[fio2.result$patientunitstayid==query.subjects[i],]
    fio2.entries$respchartvalue = as.numeric(fio2.entries$respchartvalue)
    if (dim(fio2.entries)[1]>0) {
        fio2.timestamps = sort(unique(fio2.entries$respchartoffset))
        fio2.values = sapply(fio2.timestamps,function(x) mean(fio2.entries$respchartvalue[fio2.entries$respchartoffset==x],na.rm=TRUE))
        fio2 = list(timestamps=fio2.timestamps,values=fio2.values)
    }
    # 10. GCS
    gcs = NULL
    gcs.entries = gcs.result[gcs.result$patientunitstayid==query.subjects[i],]
    if (dim(gcs.entries)[1]>0) {
        is.component = grepl("Verbal",gcs.entries$physicalexampath)|grepl("Motor",gcs.entries$physicalexampath)|grepl("Eyes",gcs.entries$physicalexampath)
        gcs.timestamps = sort(unique(gcs.entries$physicalexamoffset[is.component]))
        gcs.values = sapply(gcs.timestamps,function(x) sum(as.numeric(gcs.entries$physicalexamvalue[gcs.entries$physicalexamoffset==x&is.component])))
        gcs = list(timestamps=gcs.timestamps,values=gcs.values)
    }
    # 11. Bilirubin
    bili = NULL
    bili.entries = bili.result[bili.result$patientunitstayid==query.subjects[i],]
    bili.entries$labresult = as.numeric(bili.entries$labresult)
    if (dim(bili.entries)[1]>0) {
        bili.timestamps = sort(unique(bili.entries$labresultoffset))
        bili.values = sapply(bili.timestamps,function(x) mean(bili.entries$labresult[bili.entries$labresultoffset==x]))
        bili = list(timestamps=bili.timestamps,values=bili.values)
    }
    # 12. Platelets
    platelets = NULL
    platelets.entries = platelets.result[platelets.result$patientunitstayid==query.subjects[i],]
    platelets.entries$labresult = as.numeric(platelets.entries$labresult)
    if (dim(platelets.entries)[1]>0) {
        platelets.timestamps = sort(unique(platelets.entries$labresultoffset))
        platelets.values = sapply(platelets.timestamps,function(x) mean(platelets.entries$labresult[platelets.entries$labresultoffset==x]))
        platelets = list(timestamps=platelets.timestamps,values=platelets.values)
    }
    # 13. Creatinine
    creat = NULL
    creat.entries = creat.result[creat.result$patientunitstayid==query.subjects[i],]
    creat.entries$labresult = as.numeric(creat.entries$labresult)
    if (dim(creat.entries)[1]>0) {
        creat.timestamps = sort(unique(creat.entries$labresultoffset))
        creat.values = sapply(creat.timestamps,function(x) mean(creat.entries$labresult[creat.entries$labresultoffset==x]))
        creat = list(timestamps=creat.timestamps,values=creat.values)
    }
    # 14. Lactate
    lactate = NULL
    lactate.entries = lact.result[lact.result$patientunitstayid==query.subjects[i],]
    lactate.entries$labresult = as.numeric(lactate.entries$labresult)
    if (dim(lactate.entries)[1]>0) {
        lactate.timestamps = sort(unique(lactate.entries$labresultoffset))
        lactate.values = sapply(lactate.timestamps,function(x) mean(lactate.entries$labresult[lactate.entries$labresultoffset==x]))
        lactate = list(timestamps=lactate.timestamps,values=lactate.values)
    }
    # 15. BUN
    bun = NULL
    bun.entries = bun.result[bun.result$patientunitstayid==query.subjects[i],]
    bun.entries$labresult = as.numeric(bun.entries$labresult)
    if (dim(bun.entries)[1]>0) {
        bun.timestamps = sort(unique(bun.entries$labresultoffset))
        bun.values = sapply(bun.timestamps,function(x) mean(bun.entries$labresult[bun.entries$labresultoffset==x]))
        bun = list(timestamps=bun.timestamps,values=bun.values)
    }
    # 16. Arterial pH
    ph = NULL
    ph.entries = ph.result[ph.result$patientunitstayid==query.subjects[i],]
    ph.entries$labresult = as.numeric(ph.entries$labresult)
    if (dim(ph.entries)[1]>0) {
        ph.timestamps = sort(unique(ph.entries$labresultoffset))
        ph.values = sapply(ph.timestamps,function(x) mean(ph.entries$labresult[ph.entries$labresultoffset==x]))
        ph = list(timestamps=ph.timestamps,values=ph.values)
    }
    # 17. WBC
    wbc = NULL
    wbc.entries = wbc.result[wbc.result$patientunitstayid==query.subjects[i],]
    wbc.entries$labresult = as.numeric(wbc.entries$labresult)
    if (dim(wbc.entries)[1]>0) {
        wbc.timestamps = sort(unique(wbc.entries$labresultoffset))
        wbc.values = sapply(wbc.timestamps,function(x) mean(wbc.entries$labresult[wbc.entries$labresultoffset==x]))
        wbc = list(timestamps=wbc.timestamps,values=wbc.values)
    }
    # 18. PaCO2
    paco2 = NULL
    paco2.entries = paco2.result[paco2.result$patientunitstayid==query.subjects[i],]
    paco2.entries$labresult = as.numeric(paco2.entries$labresult)
    if (dim(paco2.entries)[1]>0) {
        paco2.timestamps = sort(unique(paco2.entries$labresultoffset))
        paco2.values = sapply(paco2.timestamps,function(x) mean(paco2.entries$labresult[paco2.entries$labresultoffset==x]))
        paco2 = list(timestamps=paco2.timestamps,values=paco2.values)
    }
    # 19. Hemoglobin
    hgb = NULL
    hgb.entries = hgb.result[hgb.result$patientunitstayid==query.subjects[i],]
    hgb.entries$labresult = as.numeric(hgb.entries$labresult)
    if (dim(hgb.entries)[1]>0) {
        hgb.timestamps = sort(unique(hgb.entries$labresultoffset))
        hgb.values = sapply(hgb.timestamps,function(x) mean(hgb.entries$labresult[hgb.entries$labresultoffset==x]))
        hgb = list(timestamps=hgb.timestamps,values=hgb.values)
    }
    # 20. Hematocrit
    hct = NULL
    hct.entries = hct.result[hct.result$patientunitstayid==query.subjects[i],]
    hct.entries$labresult = as.numeric(hct.entries$labresult)
    if (dim(hct.entries)[1]>0) {
        hct.timestamps = sort(unique(hct.entries$labresultoffset))
        hct.values = sapply(hct.timestamps,function(x) mean(hct.entries$labresult[hct.entries$labresultoffset==x]))
        hct = list(timestamps=hct.timestamps,values=hct.values)
    }
    # 21. Potassium
    potassium = NULL
    potassium.entries = potassium.result[potassium.result$patientunitstayid==query.subjects[i],]
    potassium.entries$labresult = as.numeric(potassium.entries$labresult)
    if (dim(potassium.entries)[1]>0) {
        potassium.timestamps = sort(unique(potassium.entries$labresultoffset))
        potassium.values = sapply(potassium.timestamps,function(x) mean(potassium.entries$labresult[potassium.entries$labresultoffset==x]))
        potassium = list(timestamps=potassium.timestamps,values=potassium.values)
    }
    # 22. Urine
    urine = NULL
    urine.entries = urine.result[urine.result$patientunitstayid==query.subjects[i],]
    urine.entries$cellvaluenumeric = as.numeric(urine.entries$cellvaluenumeric)
    if (dim(urine.entries)[1]>0) {
        urine.timestamps = sort(unique(urine.entries$intakeoutputoffset))
        urine.values = sapply(urine.timestamps, function(x) sum(urine.entries$cellvaluenumeric[urine.entries$intakeoutputoffset==x]))
        urine = list(timestamps=urine.timestamps,values=urine.values)
    }


    # Calculate ventilation intervals - what to do about starts with no stop time?
    vent = NULL
    vent.entries = vent.result[vent.result$patientunitstayid==query.subjects[i],]
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

    dop.entries = dop.result[dop.result$patientunitstayid==query.subjects[i],]
    dob.entries = dob.result[dob.result$patientunitstayid==query.subjects[i],]
    ep.entries = ep.result[ep.result$patientunitstayid==query.subjects[i],]
    norep.entries = norep.result[norep.result$patientunitstayid==query.subjects[i],]

    if (dim(dop.entries)[1]>0) {
        dop.timestamps = sort(unique(dop.entries$infusionoffset))
        dop.values = sapply(dop.timestamps,function(x) mean(dop.entries$drugrate[dop.entries$infusionoffset==x]))
        dop = list(timestamps=dop.timestamps, values = dop.values)
    }

    if (dim(dob.entries)[1]>0) {
        dob.timestamps = sort(unique(dob.entries$infusionoffset))
        dob.values = sapply(dob.timestamps,function(x) mean(dob.entries$drugrate[dob.entries$infusionoffset==x]))
        dob = list(timestamps=dob.timestamps, values = dob.values)
    }

    if (dim(ep.entries)[1]>0) {
        ep.timestamps = sort(unique(ep.entries$infusionoffset))
        ep.values = sapply(ep.timestamps,function(x) mean(ep.entries$drugrate[ep.entries$infusionoffset==x]))
        ep = list(timestamps=ep.timestamps, values = ep.values)
    }

    if (dim(norep.entries)[1]>0) {
        norep.timestamps = sort(unique(norep.entries$infusionoffset))
        norep.values = sapply(norep.timestamps,function(x) mean(norep.entries$drugrate[norep.entries$infusionoffset==x]))
        norep = list(timestamps=norep.timestamps, values = norep.values)
    }

    clinical.data[[i]] = list(subject.id=query.subjects[i],hr=hr,sbp=sbp,dbp=dbp,mbp=mbp,resp=resp,temp=temp,cvp=cvp,pao2=pao2,fio2=fio2,gcs=gcs,bili=bili,platelets=platelets,creat=creat,lactate=lactate,bun=bun,ph=ph,wbc=wbc,paco2=paco2,hgb=hgb,hct=hct,potassium=potassium,urine=urine,vent=vent,dop=dop,dob=dob,ep=ep,norep=norep)

}

toc()

saveRDS(clinical.data,"data/eicu/clinical_data_icd9_sofa_vent.rds")

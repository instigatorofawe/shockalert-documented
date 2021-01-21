rm(list=ls())
library(pracma)
library(tictoc)
library(lubridate)

load("data/mimic/query.items.mimic3.rdata")
load("data/mimic/input.data.rdata")

input.data.cv = input.data.cv[!is.na(input.data.cv$icustay_id),]
input.data.cv$charttime = as_datetime(input.data.cv$charttime,tz="GMT")

input.data.mv = input.data.mv[!is.na(input.data.mv$icustay_id),]
input.data.mv$starttime = as_datetime(input.data.mv$starttime,tz="GMT")

chart.data = readRDS("data/mimic/chart.data.rds")
chart.data = chart.data[!is.na(chart.data$icustay_id),]
chart.data$charttime = as_datetime(chart.data$charttime,tz="GMT")

urine.data = readRDS("data/mimic/urine.data.rds")
urine.data = urine.data[!is.na(urine.data$icustay_id),]
urine.data$charttime = as_datetime(urine.data$charttime,tz="GMT")

icu.stays = unique(chart.data$icustay_id)
interval = 100
clinical.data = vector(mode="list",length=length(icu.stays))

tic()
for (i in 1:length(icu.stays)) {
    if (i %% interval == 0) {
        fprintf("%d of %d...\n", i, length(icu.stays))
    }

    current.entries = chart.data[chart.data$icustay_id == icu.stays[i],]
    current.cv.entries = input.data.cv[input.data.cv$icustay_id == icu.stays[i],]
    current.mv.entries = input.data.mv[input.data.mv$icustay_id == icu.stays[i],]
    current.urine.entries = urine.data[urine.data$icustay_id == icu.stays[i],]

    # 1. HR
    hr = NULL
    hr.entries = current.entries[is.element(current.entries$itemid,hr.items),]
    if (dim(hr.entries)[1]>0) {
        timestamps = sort(unique(hr.entries$charttime))
        values = sapply(timestamps, function(x) mean(hr.entries$valuenum[hr.entries$charttime==x],na.rm=T))
        hr = list(timestamps=timestamps,values=values)
    }

    # 2. SBP
    sbp = NULL
    sbp.entries = current.entries[is.element(current.entries$itemid,sbp.items),]
    sbp.nbp.entries = current.entries[is.element(current.entries$itemid,sbp.nbp.items),]
    if (dim(sbp.entries)[1]>0 || dim(sbp.nbp.entries)[1]>0) {
        timestamps = sort(unique(c(sbp.entries$charttime, sbp.nbp.entries$charttime)))
        values = sapply(timestamps, function(x) mean(sbp.entries$valuenum[sbp.entries$charttime==x],na.rm=T))
        if (any(is.na(values))) {
            values[is.na(values)] = sapply(timestamps[is.na(values)], function(x) mean(sbp.nbp.entries$valuenum[sbp.nbp.entries$charttime==x],na.rm=T))
        }
        sbp = list(timestamps=timestamps,values=values)
    }

    # 3. DBP
    dbp = NULL
    dbp.entries = current.entries[is.element(current.entries$itemid,dbp.items),]
    dbp.nbp.entries = current.entries[is.element(current.entries$itemid,dbp.nbp.items),]
    if (dim(dbp.entries)[1]>0 || dim(dbp.nbp.entries)[1]>0) {
        timestamps = sort(unique(c(dbp.entries$charttime, dbp.nbp.entries$charttime)))
        values = sapply(timestamps, function(x) mean(dbp.entries$valuenum[dbp.entries$charttime==x],na.rm=T))
        if (any(is.na(values))) {
            values[is.na(values)] = sapply(timestamps[is.na(values)], function(x) mean(dbp.nbp.entries$valuenum[dbp.nbp.entries$charttime==x],na.rm=T))
        }
        dbp = list(timestamps=timestamps,values=values)
    }

    # 4. MBP
    mbp = NULL
    mbp.entries = current.entries[is.element(current.entries$itemid,mbp.items),]
    mbp.nbp.entries = current.entries[is.element(current.entries$itemid,mbp.nbp.items),]
    if (dim(mbp.entries)[1]>0 || dim(mbp.nbp.entries)[1]>0) {
        timestamps = sort(unique(c(mbp.entries$charttime, mbp.nbp.entries$charttime)))
        values = sapply(timestamps, function(x) mean(mbp.entries$valuenum[mbp.entries$charttime==x],na.rm=T))
        if (any(is.na(values))) {
            values[is.na(values)] = sapply(timestamps[is.na(values)], function(x) mean(mbp.nbp.entries$valuenum[mbp.nbp.entries$charttime==x],na.rm=T))
        }
        mbp = list(timestamps=timestamps,values=values)
    }

    # 5. Respiratory Rate
    resp = NULL
    resp.entries = current.entries[is.element(current.entries$itemid,resp.items),]
    if (dim(resp.entries)[1]>0) {
        timestamps = sort(unique(resp.entries$charttime))
        values = sapply(timestamps, function(x) mean(resp.entries$valuenum[resp.entries$charttime==x],na.rm=T))
        resp = list(timestamps=timestamps,values=values)
    }

    # 6. Temperature
    temp = NULL
    temp.c.entries = current.entries[is.element(current.entries$itemid,temp.c.items),]
    temp.f.entries = current.entries[is.element(current.entries$itemid,temp.f.items),]
    if (dim(temp.c.entries)[1]>0 || dim(temp.f.entries)[1]>0) {
        timestamps = sort(unique(temp.c.entries$charttime,temp.f.entries$charttime))
        values = sapply(timestamps, function(x) mean(c(temp.c.entries$valuenum[temp.c.entries$charttime==x],(temp.f.entries$valuenum[temp.f.entries$charttime==x]-32)*5/9),na.rm=T))
        temp = list(timestamps=timestamps,values=values)
    }

    # 7. CVP
    cvp = NULL
    cvp.entries = current.entries[is.element(current.entries$itemid,cvp.items),]
    if (dim(cvp.entries)[1]>0) {
        timestamps = sort(unique(cvp.entries$charttime))
        values = sapply(timestamps, function(x) mean(cvp.entries$valuenum[cvp.entries$charttime==x],na.rm=T))
        cvp = list(timestamps=timestamps,values=values)
    }

    # 8. PaO2
    pao2 = NULL
    pao2.entries = current.entries[is.element(current.entries$itemid,pao2.items),]
    if (dim(pao2.entries)[1]>0) {
        timestamps = sort(unique(pao2.entries$charttime))
        values = sapply(timestamps, function(x) mean(pao2.entries$valuenum[pao2.entries$charttime==x],na.rm=T))
        pao2 = list(timestamps=timestamps,values=values)
    }

    # 9. FiO2
    fio2 = NULL
    fio2.entries = current.entries[is.element(current.entries$itemid,fio2.items)&!is.na(current.entries$valuenum),]
    if (dim(fio2.entries)[1]>0) {
        timestamps = sort(unique(fio2.entries$charttime))
        values = sapply(timestamps, function(x) mean(fio2.entries$valuenum[fio2.entries$charttime==x],na.rm=T))
        values[values>1] = values[values>1]/100
        fio2 = list(timestamps=timestamps,values=values)
    }

    # 10. GCS
    gcs = NULL
    gcs.entries = current.entries[is.element(current.entries$itemid,gcs.items),]
    gcs.mv.entries = current.entries[is.element(current.entries$itemid,gcs.mv.items),]

    if (dim(gcs.entries)[1]>0 || dim(gcs.mv.entries)[1]>0) {
        timestamps = sort(unique(c(gcs.entries$charttime,gcs.mv.entries$charttime)))

        gcs.values = rep(NA,length(timestamps))
        if (dim(gcs.entries)[1]>0) {
            gcs.values = sapply(timestamps, function(x) mean(gcs.entries$valuenum[gcs.entries$charttime==x]))
        }
        gcs.mv.values = rep(NA,length(timestamps))
        if (dim(gcs.mv.entries)[1]>0) {
            gcs.mv.values = sapply(timestamps, function(x) sum(gcs.mv.entries$valuenum[gcs.mv.entries$charttime==x]))
        }

        values = rowMeans(cbind(gcs.values,gcs.mv.values),na.rm=T)
        gcs = list(timestamps=timestamps,values=values)
    }

    # 11. Bilirubin
    bili = NULL
    bili.entries = current.entries[is.element(current.entries$itemid,bili.items),]
    if (dim(bili.entries)[1]>0) {
        timestamps = sort(unique(bili.entries$charttime))
        values = sapply(timestamps, function(x) mean(bili.entries$valuenum[bili.entries$charttime==x],na.rm=T))
        bili = list(timestamps=timestamps,values=values)
    }

    # 12. Platelets
    platelets = NULL
    platelets.entries = current.entries[is.element(current.entries$itemid,platelets.items),]
    if (dim(platelets.entries)[1]>0) {
        timestamps = sort(unique(platelets.entries$charttime))
        values = sapply(timestamps, function(x) mean(platelets.entries$valuenum[platelets.entries$charttime==x],na.rm=T))
        platelets = list(timestamps=timestamps,values=values)
    }

    # 13. Creatinine
    creat = NULL
    creat.entries = current.entries[is.element(current.entries$itemid,creat.items),]
    if (dim(creat.entries)[1]>0) {
        timestamps = sort(unique(creat.entries$charttime))
        values = sapply(timestamps, function(x) mean(creat.entries$valuenum[creat.entries$charttime==x],na.rm=T))
        creat = list(timestamps=timestamps,values=values)
    }

    # 14. Lactate
    lact = NULL
    lact.entries = current.entries[is.element(current.entries$itemid,lact.items),]
    if (dim(lact.entries)[1]>0) {
        timestamps = sort(unique(lact.entries$charttime))
        values = sapply(timestamps, function(x) mean(lact.entries$valuenum[lact.entries$charttime==x],na.rm=T))
        lact = list(timestamps=timestamps,values=values)
    }

    # 15. BUN
    bun = NULL
    bun.entries = current.entries[is.element(current.entries$itemid,bun.items),]
    if (dim(bun.entries)[1]>0) {
        timestamps = sort(unique(bun.entries$charttime))
        values = sapply(timestamps, function(x) mean(bun.entries$valuenum[bun.entries$charttime==x],na.rm=T))
        bun = list(timestamps=timestamps,values=values)
    }

    # 16. Arterial pH
    ph = NULL
    ph.entries = current.entries[is.element(current.entries$itemid,ph.items),]
    if (dim(ph.entries)[1]>0) {
        timestamps = sort(unique(ph.entries$charttime))
        values = sapply(timestamps, function(x) mean(ph.entries$valuenum[ph.entries$charttime==x],na.rm=T))
        ph = list(timestamps=timestamps,values=values)
    }

    # 17. WBC
    wbc = NULL
    wbc.entries = current.entries[is.element(current.entries$itemid,wbc.items),]
    if (dim(wbc.entries)[1]>0) {
        timestamps = sort(unique(wbc.entries$charttime))
        values = sapply(timestamps, function(x) mean(wbc.entries$valuenum[wbc.entries$charttime==x],na.rm=T))
        wbc = list(timestamps=timestamps,values=values)
    }

    # 18. PaCO2
    paco2 = NULL
    paco2.entries = current.entries[is.element(current.entries$itemid,paco2.items),]
    if (dim(paco2.entries)[1]>0) {
        timestamps = sort(unique(paco2.entries$charttime))
        values = sapply(timestamps, function(x) mean(paco2.entries$valuenum[paco2.entries$charttime==x],na.rm=T))
        paco2 = list(timestamps=timestamps,values=values)
    }

    # 19. Hemoglobin
    hgb = NULL
    hgb.entries = current.entries[is.element(current.entries$itemid,hgb.items),]
    if (dim(hgb.entries)[1]>0) {
        timestamps = sort(unique(hgb.entries$charttime))
        values = sapply(timestamps, function(x) mean(hgb.entries$valuenum[hgb.entries$charttime==x],na.rm=T))
        hgb = list(timestamps=timestamps,values=values)
    }

    # 20. Hematocrit
    hct = NULL
    hct.entries = current.entries[is.element(current.entries$itemid,hct.items),]
    if (dim(hct.entries)[1]>0) {
        timestamps = sort(unique(hct.entries$charttime))
        values = sapply(timestamps, function(x) mean(hct.entries$valuenum[hct.entries$charttime==x],na.rm=T))
        hct = list(timestamps=timestamps,values=values)
    }

    # 21. Potassium
    potassium = NULL
    potassium.entries = current.entries[is.element(current.entries$itemid,potassium.items),]
    if (dim(potassium.entries)[1]>0) {
        timestamps = sort(unique(potassium.entries$charttime))
        values = sapply(timestamps, function(x) mean(potassium.entries$valuenum[potassium.entries$charttime==x],na.rm=T))
        potassium = list(timestamps=timestamps,values=values)
    }
    
    # Vasopressors
    # 22. Epinephrine
    epi = NULL
    epi.cv.entries = current.cv.entries[is.element(current.cv.entries$itemid,epi.items),]
    epi.mv.entries = current.mv.entries[is.element(current.mv.entries$itemid,epi.items),]
    if (dim(epi.cv.entries)[1]>0||dim(epi.mv.entries)[1]>0) {
        timestamps = sort(unique(c(epi.cv.entries$charttime,epi.mv.entries$starttime)))
        values = sapply(timestamps, function(x) mean(c(epi.cv.entries$rate[epi.cv.entries$charttime==x],epi.mv.entries$rate[epi.mv.entries$starttime==x]),na.rm=T))
        epi = list(timestamps=timestamps,values=values)
    }

    # 23. Dopamine
    dop = NULL
    dop.cv.entries = current.cv.entries[is.element(current.cv.entries$itemid,dop.items),]
    dop.mv.entries = current.mv.entries[is.element(current.mv.entries$itemid,dop.items),]
    if (dim(dop.cv.entries)[1]>0||dim(dop.mv.entries)[1]>0) {
        timestamps = sort(unique(c(dop.cv.entries$charttime,dop.mv.entries$starttime)))
        values = sapply(timestamps, function(x) mean(c(dop.cv.entries$rate[dop.cv.entries$charttime==x],dop.mv.entries$rate[dop.mv.entries$starttime==x]),na.rm=T))
        dop = list(timestamps=timestamps,values=values)
    }

    # 24. Dobutamine
    dob = NULL
    dob.cv.entries = current.cv.entries[is.element(current.cv.entries$itemid,dob.items),]
    dob.mv.entries = current.mv.entries[is.element(current.mv.entries$itemid,dob.items),]
    if (dim(dob.cv.entries)[1]>0||dim(dob.mv.entries)[1]>0) {
        timestamps = sort(unique(c(dob.cv.entries$charttime,dob.mv.entries$starttime)))
        values = sapply(timestamps, function(x) mean(c(dob.cv.entries$rate[dob.cv.entries$charttime==x],dob.mv.entries$rate[dob.mv.entries$starttime==x]),na.rm=T))
        dob = list(timestamps=timestamps,values=values)
    }

    # 25. Norepinephrine
    norepi = NULL
    norepi.cv.entries = current.cv.entries[is.element(current.cv.entries$itemid,norepi.items),]
    norepi.mv.entries = current.mv.entries[is.element(current.mv.entries$itemid,norepi.items),]
    if (dim(norepi.cv.entries)[1]>0||dim(norepi.mv.entries)[1]>0) {
        timestamps = sort(unique(c(norepi.cv.entries$charttime,norepi.mv.entries$starttime)))
        values = sapply(timestamps, function(x) mean(c(norepi.cv.entries$rate[norepi.cv.entries$charttime==x],norepi.mv.entries$rate[norepi.mv.entries$starttime==x]),na.rm=T))
        norepi = list(timestamps=timestamps,values=values)
    }

    # 26. Phenylephrine
    phen = NULL
    phen.cv.entries = current.cv.entries[is.element(current.cv.entries$itemid,phen.items),]
    phen.mv.entries = current.mv.entries[is.element(current.mv.entries$itemid,phen.items),]
    if (dim(phen.cv.entries)[1]>0||dim(phen.mv.entries)[1]>0) {
        timestamps = sort(unique(c(phen.cv.entries$charttime,phen.mv.entries$starttime)))
        values = sapply(timestamps, function(x) mean(c(phen.cv.entries$rate[phen.cv.entries$charttime==x],phen.mv.entries$rate[phen.mv.entries$starttime==x]),na.rm=T))
        phen = list(timestamps=timestamps,values=values)
    }

    # 27. Vasopressin
    vasopressin = NULL
    vasopressin.cv.entries = current.cv.entries[is.element(current.cv.entries$itemid,vasopressin.items),]
    vasopressin.mv.entries = current.mv.entries[is.element(current.mv.entries$itemid,vasopressin.items),]
    if (dim(vasopressin.cv.entries)[1]>0||dim(vasopressin.mv.entries)[1]>0) {
        timestamps = sort(unique(c(vasopressin.cv.entries$charttime,vasopressin.mv.entries$starttime)))
        values = sapply(timestamps, function(x) mean(c(vasopressin.cv.entries$rate[vasopressin.cv.entries$charttime==x],vasopressin.mv.entries$rate[vasopressin.mv.entries$starttime==x]),na.rm=T))
        vasopressin = list(timestamps=timestamps,values=values)
    }

    # 28. Fluid administration
    fluids = NULL
    fluid.cv.entries = current.cv.entries[current.cv.entries$amountuom=="ml",]
    fluid.mv.entries = current.mv.entries[current.mv.entries$amountuom=="ml",]
    if (dim(fluid.cv.entries)[1]>0||dim(fluid.mv.entries)[1]>0) {
        timestamps = sort(unique(c(fluid.cv.entries$charttime,fluid.mv.entries$starttime)))
        values = sapply(timestamps, function(x) sum(c(fluid.cv.entries$amount[fluid.cv.entries$charttime==x],fluid.mv.entries$amount[fluid.mv.entries$starttime==x]),na.rm=T))
        fluids = list(timestamps=timestamps,values=values)
    }

    # 29. Urine output
    urine = NULL
    if (dim(current.urine.entries)[1]>0) {
        timestamps = sort(unique(current.urine.entries$charttime))
        values = sapply(timestamps, function(x) sum(current.urine.entries$value[current.urine.entries$charttime==x],na.rm=T))
        urine = list(timestamps=timestamps,values=values)
    }

    clinical.data[[i]] = list(icustay.id = icu.stays[i], hr=hr,sbp=sbp,dbp=dbp,mbp=mbp,resp=resp,temp=temp,
                              cvp=cvp,pao2=pao2,fio2=fio2,gcs=gcs,bili=bili,platelets=platelets,creat=creat,
                              lactate=lact,bun=bun,ph=ph,wbc=wbc,paco2=paco2,hgb=hgb,hct=hct,potassium=potassium,
                              epi=epi,dop=dop,dob=dob,norepi=norepi,phen=phen,vasopressin=vasopressin,fluids=fluids,urine=urine)
}
toc()

saveRDS(clinical.data,file="data/mimic/clinical.data.mimic.rds")
eval.table.with.sofa.comorbidities = function(timestamps, data, comorbidities) {
    hr = rep(NA, length(timestamps))
    if (!is.null(data$hr)) {
        hr = eval.carry.forward(timestamps,data$hr$timestamps,data$hr$values)
    }
    sbp = rep(NA, length(timestamps))
    if (!is.null(data$sbp)) {
        sbp = eval.carry.forward(timestamps,data$sbp$timestamps,data$sbp$values)
    }
    dbp = rep(NA, length(timestamps))
    if (!is.null(data$dbp)) {
        dbp = eval.carry.forward(timestamps,data$dbp$timestamps,data$dbp$values)
    }
    mbp = rep(NA, length(timestamps))
    if (!is.null(data$mbp)) {
        mbp = eval.carry.forward(timestamps,data$mbp$timestamps,data$mbp$values)
    }
    resp = rep(NA, length(timestamps))
    if (!is.null(data$resp)) {
        resp = eval.carry.forward(timestamps,data$resp$timestamps,data$resp$values)
    }
    temp = rep(NA, length(timestamps))
    if (!is.null(data$temp)) {
        temp = eval.carry.forward(timestamps,data$temp$timestamps,data$temp$values)
    }
    cvp = rep(NA, length(timestamps))
    if (!is.null(data$cvp)) {
        cvp = eval.carry.forward(timestamps,data$cvp$timestamps,data$cvp$values)
    }
    pao2 = rep(NA, length(timestamps))
    if (!is.null(data$pao2)) {
        pao2 = eval.carry.forward(timestamps,data$pao2$timestamps,data$pao2$values)
    }
    fio2 = rep(NA, length(timestamps))
    if (!is.null(data$fio2)) {
        fio2 = eval.carry.forward(timestamps,data$fio2$timestamps,data$fio2$values)
    }
    gcs = rep(NA, length(timestamps))
    if (!is.null(data$gcs)&length(data$gcs$timestamps)>0) {
        gcs = eval.carry.forward(timestamps,data$gcs$timestamps,data$gcs$values)
    }
    bili = rep(NA, length(timestamps))
    if (!is.null(data$bili)) {
        bili = eval.carry.forward(timestamps,data$bili$timestamps,data$bili$values)
    }
    platelets = rep(NA, length(timestamps))
    if (!is.null(data$platelets)) {
        platelets = eval.carry.forward(timestamps,data$platelets$timestamps,data$platelets$values)
    }
    creat = rep(NA, length(timestamps))
    if (!is.null(data$creat)) {
        creat = eval.carry.forward(timestamps,data$creat$timestamps,data$creat$values)
    }
    lactate = rep(NA, length(timestamps))
    if (!is.null(data$lactate)) {
        lactate = eval.carry.forward(timestamps,data$lactate$timestamps,data$lactate$values)
    }
    bun = rep(NA, length(timestamps))
    if (!is.null(data$bun)) {
        bun = eval.carry.forward(timestamps,data$bun$timestamps,data$bun$values)
    }
    ph = rep(NA, length(timestamps))
    if (!is.null(data$ph)) {
        ph = eval.carry.forward(timestamps,data$ph$timestamps,data$ph$values)
    }
    wbc = rep(NA, length(timestamps))
    if (!is.null(data$wbc)) {
        wbc = eval.carry.forward(timestamps,data$wbc$timestamps,data$wbc$values)
    }
    paco2 = rep(NA, length(timestamps))
    if (!is.null(data$paco2)) {
        paco2 = eval.carry.forward(timestamps,data$paco2$timestamps,data$paco2$values)
    }
    hgb = rep(NA, length(timestamps))
    if (!is.null(data$hgb)) {
        hgb = eval.carry.forward(timestamps,data$hgb$timestamps,data$hgb$values)
    }
    hct = rep(NA, length(timestamps))
    if (!is.null(data$hct)) {
        hct = eval.carry.forward(timestamps,data$hct$timestamps,data$hct$values)
    }
    potassium = rep(NA, length(timestamps))
    if (!is.null(data$potassium)) {
        potassium = eval.carry.forward(timestamps,data$potassium$timestamps,data$potassium$values)
    }
    urine = rep(NA, length(timestamps))
    if (!is.null(data$urine)) {
        urine = eval.sum.in.past(timestamps,data$urine$timestamps,data$urine$values,24*60)
    }

    # Determine ventilator usage
    vent = rep(NA, length(timestamps))
    if (!is.null(data$vent)) {
        vent = eval.interval(timestamps,data$vent$starts,data$vent$stops)
    }

    # Calculate SOFA scores: need to evaluate features at all available timestamps, then re-evaluate as most severe
    # in past 24 hours at timestamps for which we are generating data tables
    resp.sofa = rep(0, length(timestamps))

    if (!is.null(data$pao2)) {
        resp.sofa.timestamps = sort(unique(c(data$pao2$timestamps,data$fio2$timestamps)))
        resp.sofa.raw = rep(0, length(resp.sofa.timestamps))
        sofa.pao2 = eval.carry.forward(resp.sofa.timestamps,data$pao2$timestamps,data$pao2$values)
        sofa.fio2 = rep(NA, length(resp.sofa.timestamps))
        sofa.vent = rep(NA, length(resp.sofa.timestamps))

        if(!is.null(data$fio2)) {
            sofa.fio2 = eval.carry.forward(resp.sofa.timestamps,data$fio2$timestamps,data$fio2$values)
        }
        if(!is.null(data$vent)) {
            sofa.vent = eval.interval(resp.sofa.timestamps,data$vent$starts,data$vent$stops)
        }

        sofa.fio2[is.na(sofa.fio2)] = 21
        pao2.fio2.ratio = sofa.pao2 / sofa.fio2 * 100

        resp.sofa.raw[pao2.fio2.ratio<400] = 1
        resp.sofa.raw[pao2.fio2.ratio<300] = 2
        resp.sofa.raw[pao2.fio2.ratio<200&sofa.vent] = 3
        resp.sofa.raw[pao2.fio2.ratio<100&sofa.vent] = 4

        resp.sofa = eval.max.in.past(timestamps, resp.sofa.timestamps, resp.sofa.raw, 24*60, 0)
    }

    # Nervous: GCS
    nervous.sofa = rep(0, length(timestamps))

    # Edge case exists where there are GCS entries in database (physicalexam table) but no numeric evaluation
    if (!is.null(data$gcs)&length(data$gcs$timestamps)>0) {
        nervous.sofa.timestamps = sort(unique(data$gcs$timestamps))
        nervous.sofa.raw = rep(0, length(nervous.sofa.timestamps))

        current.gcs = eval.carry.forward(nervous.sofa.timestamps,data$gcs$timestamps,data$gcs$values)
        nervous.sofa.raw[current.gcs<15&current.gcs>=13] = 1
        nervous.sofa.raw[current.gcs<13&current.gcs>=10] = 2
        nervous.sofa.raw[current.gcs<10&current.gcs>=6] = 3
        nervous.sofa.raw[current.gcs<6] = 4

        nervous.sofa = eval.max.in.past(timestamps, nervous.sofa.timestamps, nervous.sofa.raw, 24*60, 0)
    }

    # Cardio: map, vasopressors
    cardio.sofa.timestamps = sort(unique(c(data$map$timestamps,data$dop$timestamps,data$dob$timestamps,data$ep$timestamps,data$norep$timestamps)))
    cardio.sofa.raw = rep(0, length(cardio.sofa.timestamps))

    cardio.sofa = rep(0, length(timestamps))
    vasopressors = rep(0, length(timestamps))

    if (!is.null(data$map)) {
        current.map = eval.carry.forward(cardio.sofa.timestamps,data$map$timestamps,data$map$values)
        cardio.sofa.raw[current.map < 70] = 1
    }

    if (!is.null(data$dop)) {
        # If vasopressors given in the past hour
        current.dop = eval.carry.forward(cardio.sofa.timestamps,data$dop$timestamps,data$dop$values,60)
        cardio.sofa.raw[current.dop>0] = 2
        vasopressors[eval.carry.forward(timestamps,data$dop$timestamps,data$dop$values,60)>0] = TRUE
    }

    if (!is.null(data$dob)) {
        current.dob = eval.carry.forward(cardio.sofa.timestamps,data$dob$timestamps,data$dob$values,60)
        cardio.sofa.raw[current.dob>0] = 2
        vasopressors[eval.carry.forward(timestamps,data$dob$timestamps,data$dob$values,60)>0] = TRUE
    }

    if (!is.null(data$ep)) {
        current.ep = eval.carry.forward(cardio.sofa.timestamps,data$ep$timestamps,data$ep$values,60)
        cardio.sofa.raw[current.ep>0] = 2
        vasopressors[eval.carry.forward(timestamps,data$ep$timestamps,data$ep$values,60)>0] = TRUE
    }

    if (!is.null(data$norep)) {
        current.norep = eval.carry.forward(timestamps,data$norep$timestamps,data$norep$values,60)
        cardio.sofa[current.norep>0] = 2
        vasopressors[current.norep>0] = TRUE
    }

    cardio.sofa = eval.max.in.past(timestamps, timestamps, cardio.sofa, 24*60)

    # Liver: bilirubin
    liver.sofa = rep(0, length(timestamps))

    if (!is.null(data$bili)) {
        bili.timestamps = sort(unique(data$bili$timestamps))
        current.bili = eval.carry.forward(bili.timestamps,data$bili$timestamps,data$bili$values)
        liver.sofa.raw = rep(0, length(bili.timestamps))
        liver.sofa.raw[current.bili>=1.2&current.bili<2] = 1
        liver.sofa.raw[current.bili>=2&current.bili<6] = 2
        liver.sofa.raw[current.bili>=6&current.bili<12] = 3
        liver.sofa.raw[current.bili>=12] = 4
        liver.sofa = eval.max.in.past(timestamps, bili.timestamps, liver.sofa.raw, 24*60, 0)
    }

    # Coag: platelets
    coag.sofa = rep(0, length(timestamps))

    if (!is.null(data$platelets)) {
        coag.timestamps = sort(unique(data$platelets$timestamps))
        current.platelets = eval.carry.forward(coag.timestamps,data$platelets$timestamps,data$platelets$values)
        coag.sofa.raw = rep(0,length(coag.timestamps))
        coag.sofa.raw[current.platelets<150] = 1
        coag.sofa.raw[current.platelets<100] = 2
        coag.sofa.raw[current.platelets<50] = 3
        coag.sofa.raw[current.platelets<20] = 4
        coag.sofa = eval.max.in.past(timestamps, coag.timestamps, coag.sofa.raw, 24*60, 0)
    }

    # Kidneys: creat & urine output
    kidney.sofa = rep(0, length(timestamps))

    if (!is.null(data$creat)) {
        creat.timestamps = sort(unique(data$creat$timestamps))
        current.creat = eval.carry.forward(creat.timestamps,data$creat$timestamps,data$creat$values)
        kidney.sofa.raw = rep(0,length(creat.timestamps))
        kidney.sofa.raw[current.creat>=1.2&current.creat<2] = 1
        kidney.sofa.raw[current.creat>=2&current.creat<3.5] = 2
        kidney.sofa.raw[current.creat>=3.5&current.creat<5] = 3
        kidney.sofa.raw[current.creat>=5] = 4
        kidney.sofa = eval.max.in.past(timestamps, creat.timestamps, kidney.sofa.raw, 24*60, 0)
    }


    result = data.frame(hr=hr,sbp=sbp,dbp=dbp,mbp=mbp,resp=resp,temp=temp,cvp=cvp,pao2=pao2,fio2=fio2,gcs=gcs,bili=bili,platelets=platelets,creat=creat,lactate=lactate,bun=bun,ph=ph,wbc=wbc,paco2=paco2,hgb=hgb,hct=hct,potassium=potassium,urine=urine,resp.sofa=resp.sofa,nervous.sofa=nervous.sofa,cardio.sofa=cardio.sofa,liver.sofa=liver.sofa,coag.sofa=coag.sofa,kidney.sofa=kidney.sofa)
    result = cbind(result, as.data.frame(t(array(comorbidities, dim=c(length(comorbidities),length(timestamps))))))
    return(result)
}
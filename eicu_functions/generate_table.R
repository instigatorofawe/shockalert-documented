generate.table = function(start, end, n, data) {
    timestamps = sort(sample(start:end,n))
    hr = rep(NA, n)
    if (!is.null(data$hr)) {
        hr = eval.carry.forward(timestamps,data$hr$timestamps,data$hr$values)
    }
    sbp = rep(NA, n)
    if (!is.null(data$sbp)) {
        sbp = eval.carry.forward(timestamps,data$sbp$timestamps,data$sbp$values)
    }
    dbp = rep(NA, n)
    if (!is.null(data$dbp)) {
        dbp = eval.carry.forward(timestamps,data$dbp$timestamps,data$dbp$values)
    }
    mbp = rep(NA, n)
    if (!is.null(data$mbp)) {
        mbp = eval.carry.forward(timestamps,data$mbp$timestamps,data$mbp$values)
    }
    resp = rep(NA, n)
    if (!is.null(data$resp)) {
        resp = eval.carry.forward(timestamps,data$resp$timestamps,data$resp$values)
    }
    temp = rep(NA, n)
    if (!is.null(data$temp)) {
        temp = eval.carry.forward(timestamps,data$temp$timestamps,data$temp$values)
    }
    cvp = rep(NA, n)
    if (!is.null(data$cvp)) {
        cvp = eval.carry.forward(timestamps,data$cvp$timestamps,data$cvp$values)
    }
    pao2 = rep(NA, n)
    if (!is.null(data$pao2)) {
        pao2 = eval.carry.forward(timestamps,data$pao2$timestamps,data$pao2$values)
    }
    fio2 = rep(NA, n)
    if (!is.null(data$fio2)) {
        fio2 = eval.carry.forward(timestamps,data$fio2$timestamps,data$fio2$values)
    }
    gcs = rep(NA, n)
    if (!is.null(data$gcs)) {
        gcs = eval.carry.forward(timestamps,data$gcs$timestamps,data$gcs$values)
    }
    bili = rep(NA, n)
    if (!is.null(data$bili)) {
        bili = eval.carry.forward(timestamps,data$bili$timestamps,data$bili$values)
    }
    platelets = rep(NA, n)
    if (!is.null(data$platelets)) {
        platelets = eval.carry.forward(timestamps,data$platelets$timestamps,data$platelets$values)
    }
    creat = rep(NA, n)
    if (!is.null(data$creat)) {
        creat = eval.carry.forward(timestamps,data$creat$timestamps,data$creat$values)
    }
    lactate = rep(NA, n)
    if (!is.null(data$lactate)) {
        lactate = eval.carry.forward(timestamps,data$lactate$timestamps,data$lactate$values)
    }
    bun = rep(NA, n)
    if (!is.null(data$bun)) {
        bun = eval.carry.forward(timestamps,data$bun$timestamps,data$bun$values)
    }
    ph = rep(NA, n)
    if (!is.null(data$ph)) {
        ph = eval.carry.forward(timestamps,data$ph$timestamps,data$ph$values)
    }
    wbc = rep(NA, n)
    if (!is.null(data$wbc)) {
        wbc = eval.carry.forward(timestamps,data$wbc$timestamps,data$wbc$values)
    }
    paco2 = rep(NA, n)
    if (!is.null(data$paco2)) {
        paco2 = eval.carry.forward(timestamps,data$paco2$timestamps,data$paco2$values)
    }
    hgb = rep(NA, n)
    if (!is.null(data$hgb)) {
        hgb = eval.carry.forward(timestamps,data$hgb$timestamps,data$hgb$values)
    }
    hct = rep(NA, n)
    if (!is.null(data$hct)) {
        hct = eval.carry.forward(timestamps,data$hct$timestamps,data$hct$values)
    }
    potassium = rep(NA, n)
    if (!is.null(data$potassium)) {
        potassium = eval.carry.forward(timestamps,data$potassium$timestamps,data$potassium$values)
    }
    urine = rep(NA, n)
    if (!is.null(data$urine)) {
        urine = eval.sum.in.past(timestamps,data$urine$timestamps,data$urine$values,24*60)
    }
    result = data.frame(hr=hr,sbp=sbp,dbp=dbp,mbp=mbp,resp=resp,temp=temp,cvp=cvp,pao2=pao2,fio2=fio2,gcs=gcs,bili=bili,platelets=platelets,creat=creat,lactate=lactate,bun=bun,ph=ph,wbc=wbc,paco2=paco2,hgb=hgb,hct=hct,potassium=potassium,urine=urine)
    return(result)
}
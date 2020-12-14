rm(list=ls())

library(lubridate)
library(pracma)
library(tictoc)

source("functions/eval_carry_forward.R")
source("functions/eval_interval.R")
source("functions/eval_max_in_past.R")
source("functions/sum_in_past.R")
source("functions/eval_sum_in_past.R")


clinical.data = readRDS("clinical.data.mimic.rds")
weight.data = readRDS("weight.data.rds")
sofa.scores = vector(mode="list",length=length(clinical.data))

#patient.weights = sapply(clinical.data, function(x) mean(weight.data[weight.data$icustay_id==x$icustay.id,]$valuenum,na.rm=T))


tic("Evaluating SOFA scores")

for (i in 1:length(clinical.data)) {
    fprintf("%d of %d...\n",i,length(clinical.data))
    patient.weight = mean(weight.data[weight.data$icustay_id==clinical.data[[i]]$icustay.id,]$valuenum,na.rm=T)

    # Get unique timestamps
    timestamps = unlist(sapply(clinical.data[[i]][sapply(clinical.data[[i]],length)==2], function(x) x$timestamps))
    timestamps = sort(unique(timestamps[!is.null(timestamps)]))
    
    if (length(timestamps)==0) {
        next
    }
    
    timestamps = as_datetime(timestamps,tz="GMT")

    # Compute sofa score at each timestamp
    resp.sofa = rep(0, length(timestamps))

    # No good documentation of ventilation in MIMIC
    if (!is.null(clinical.data[[i]]$pao2)) {
        current.pao2 = rep(NA, length(timestamps))
        current.fio2 = rep(NA, length(timestamps))

        current.pao2 = eval.carry.forward(timestamps,clinical.data[[i]]$pao2$timestamps,clinical.data[[i]]$pao2$values)
        if (!is.null(clinical.data[[i]]$fio2)) {
            current.fio2 = eval.carry.forward(timestamps,clinical.data[[i]]$fio2$timestamps,clinical.data[[i]]$fio2$values)
        }

        current.fio2[is.na(current.fio2)] = 21
        pao2.fio2.ratio = current.pao2 / current.fio2 * 100

        resp.sofa[pao2.fio2.ratio<400] = 1
        resp.sofa[pao2.fio2.ratio<300] = 2
        resp.sofa[pao2.fio2.ratio<200] = 3
        resp.sofa[pao2.fio2.ratio<100] = 4

        resp.sofa = eval.max.in.past(timestamps, resp.sofa, 24*60)
    }

    # Nervous: GCS
    nervous.sofa = rep(0, length(timestamps))

    if (!is.null(clinical.data[[i]]$gcs)) {
        current.gcs = eval.carry.forward(timestamps,clinical.data[[i]]$gcs$timestamps,clinical.data[[i]]$gcs$values)
        nervous.sofa[current.gcs<15&current.gcs>=13] = 1
        nervous.sofa[current.gcs<13&current.gcs>=10] = 2
        nervous.sofa[current.gcs<10&current.gcs>=6] = 3
        nervous.sofa[current.gcs<6] = 4

        nervous.sofa = eval.max.in.past(timestamps, nervous.sofa, 24*60)
    }

    # Cardio: mbp, vasopressors
    # Difficult to determine correct units of measure of vasopressors, so just use presence/absence
    cardio.sofa = rep(0, length(timestamps))
    vasopressors = rep(FALSE, length(timestamps))

    if (!is.null(clinical.data[[i]]$mbp)) {
        current.mbp = eval.carry.forward(timestamps,clinical.data[[i]]$mbp$timestamps,clinical.data[[i]]$mbp$values)
        cardio.sofa[current.mbp < 70] = 1
    }

    if (!is.null(clinical.data[[i]]$dop)) {
        # If vasopressors given in the past hour
        current.dop = eval.carry.forward(timestamps,clinical.data[[i]]$dop$timestamps,clinical.data[[i]]$dop$values,60)
        cardio.sofa[current.dop>0] = 2
        vasopressors[current.dop>0] = TRUE
    }

    if (!is.null(clinical.data[[i]]$dob)) {
        current.dob = eval.carry.forward(timestamps,clinical.data[[i]]$dob$timestamps,clinical.data[[i]]$dob$values,60)
        cardio.sofa[current.dob>0] = 2
        vasopressors[current.dob>0] = TRUE
    }

    if (!is.null(clinical.data[[i]]$ep)) {
        current.ep = eval.carry.forward(timestamps,clinical.data[[i]]$ep$timestamps,clinical.data[[i]]$ep$values,60)
        cardio.sofa[current.ep>0] = 2
        vasopressors[current.ep>0] = TRUE
    }

    if (!is.null(clinical.data[[i]]$norep)) {
        current.norep = eval.carry.forward(timestamps,clinical.data[[i]]$norep$timestamps,clinical.data[[i]]$norep$values,60)
        cardio.sofa[current.norep>0] = 2
        vasopressors[current.norep>0] = TRUE
    }

    cardio.sofa = eval.max.in.past(timestamps, cardio.sofa, 24*60)

    # Liver: bilirubin
    liver.sofa = rep(0, length(timestamps))

    if (!is.null(clinical.data[[i]]$bili)) {
        current.bili = eval.carry.forward(timestamps,clinical.data[[i]]$bili$timestamps,clinical.data[[i]]$bili$values)
        liver.sofa[current.bili>=1.2&current.bili<2] = 1
        liver.sofa[current.bili>=2&current.bili<6] = 2
        liver.sofa[current.bili>=6&current.bili<12] = 3
        liver.sofa[current.bili>=12] = 4
        liver.sofa = eval.max.in.past(timestamps, liver.sofa, 24*60)
    }

    # Coag: platelets
    coag.sofa = rep(0, length(timestamps))

    if (!is.null(clinical.data[[i]]$platelets)) {
        current.platelets = eval.carry.forward(timestamps,clinical.data[[i]]$platelets$timestamps,clinical.data[[i]]$platelets$values)
        coag.sofa[current.platelets<150] = 1
        coag.sofa[current.platelets<100] = 2
        coag.sofa[current.platelets<50] = 3
        coag.sofa[current.platelets<20] = 4
        coag.sofa = eval.max.in.past(timestamps, coag.sofa, 24*60)
    }

    # Kidneys: creatinine and urine output
    kidney.sofa = rep(0, length(timestamps))

    if (!is.null(clinical.data[[i]]$creat)) {
        current.creat = eval.carry.forward(timestamps,clinical.data[[i]]$creat$timestamps,clinical.data[[i]]$creat$values)
        kidney.sofa[current.creat>=1.2&current.creat<2] = 1
        kidney.sofa[current.creat>=2&current.creat<3.5] = 2
        kidney.sofa[current.creat>=3.5&current.creat<5] = 3
        kidney.sofa[current.creat>=5] = 4
        kidney.sofa = eval.max.in.past(timestamps, kidney.sofa, 24*60)
    }

    lactate.criterion = rep(FALSE, length(timestamps))

    # Septic shock: lactate, vasopressors, fluid administration
    if (!is.null(clinical.data[[i]]$lactate)) {
        current.lactate = eval.carry.forward(timestamps,clinical.data[[i]]$lactate$timestamps,clinical.data[[i]]$lactate$values)
        lactate.criterion = current.lactate > 2
    }

    fluid.resuscitation = rep(FALSE, length(timestamps))

    # Determine fluid resuscitation
    if (!is.null(clinical.data[[i]]$fluids)&length(clinical.data[[i]]$fluids$timestamps)>0) {
        current.fluids = eval.sum.in.past(timestamps,clinical.data[[i]]$fluids$timestamps,clinical.data[[i]]$fluids$values,hours(1))
        fluid.resuscitation[current.fluids/patient.weight>30] = TRUE
    }

    if (!is.null(clinical.data[[i]]$urine)) {
        current.urine = eval.sum.in.past(timestamps,clinical.data[[i]]$urine$timestamps,clinical.data[[i]]$urine$values,hours(1))
        fluid.resuscitation[current.urine/patient.weight>0.5] = TRUE
    }

    if (!is.null(clinical.data[[i]]$cvp)) {
        current.cvp = eval.carry.forward(timestamps,clinical.data[[i]]$cvp$timestamps,clinical.data[[i]]$cvp$values)
        fluid.resuscitation[current.cvp>8] = TRUE
    }

    sofa.scores[[i]] = data.frame(timestamps = timestamps, resp=resp.sofa, nervous=nervous.sofa, cardio=cardio.sofa, liver=liver.sofa, coag = coag.sofa, kidney=kidney.sofa, lactate=lactate.criterion, vasopressors=vasopressors, fluids=fluid.resuscitation)
}
toc()

saveRDS(sofa.scores, file("processed/sofa_scores.rds"))

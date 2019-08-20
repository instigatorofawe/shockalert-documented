rm(list=ls())


library(lubridate)
library(pracma)
library(tictoc)

source("functions/eval_carry_forward.R")
source("functions/eval_interval.R")
source("functions/eval_max_in_past.R")
source("functions/eval_sum_in_past.R")

clinical.data = readRDS("clinical.data.mimic.rds")
weight.data = readRDS("weight.data.rds")

sepsis2.timestamps = vector(mode="list",length=length(clinical.data))

sirs = vector(mode="list",length=length(clinical.data))
severe = vector(mode="list",length=length(clinical.data))
shock = vector(mode="list",length=length(clinical.data))

for (i in 8951:length(clinical.data)) {
    fprintf("%d of %d...\n",i,length(clinical.data))
    data = clinical.data[[i]]
    timestamps = sort(unique(c(data$hr$timestamps,data$temp$timestamps,data$resp$timestamps,data$paco2$timestamps,data$wbc$timestamps,data$sbp$timestamps,data$fluids$timestamps,data$urine$timestamps,data$cvp$timestamps,data$lactate$timestamps)))
    
    
    weight = NA
    
    # Try to query weight
    current.weight = mean(weight.data[weight.data$icustay_id==data$icustay.id,]$valuenum,na.rm=T)
    if (!is.na(current.weight)) {
        weight = current.weight
    }
    
    if (!is.null(timestamps)) {
        timestamps = as_datetime(timestamps,tz="GMT")
        sepsis2.timestamps[[i]] = timestamps
        
        temp = rep(NA,length(timestamps))
        hr = rep(NA,length(timestamps))
        resp = rep(NA,length(timestamps))
        paco2 = rep(NA,length(timestamps))
        wbc = rep(NA,length(timestamps))
        sbp = rep(NA,length(timestamps))
        fluids = rep(NA,length(timestamps))
        urine = rep(NA,length(timestamps))
        cvp = rep(NA,length(timestamps))
        lact = rep(NA,length(timestamps))
        
        if (!is.null(data$temp)) {
            temp = eval.carry.forward(timestamps,data$temp$timestamps,data$temp$values)
        }
        
        if (!is.null(data$hr)) {
            hr = eval.carry.forward(timestamps,data$hr$timestamps,data$hr$values)
        }
        
        if (!is.null(data$resp)) {
            resp = eval.carry.forward(timestamps,data$resp$timestamps,data$resp$values)
        }
        
        if (!is.null(data$paco2)) {
            paco2 = eval.carry.forward(timestamps,data$paco2$timestamps,data$paco2$values)
        }
        
        if (!is.null(data$wbc)) {
            wbc = eval.carry.forward(timestamps,data$wbc$timestamps,data$wbc$values)
        }
        
        if (!is.null(data$sbp)) {
            sbp = eval.carry.forward(timestamps,data$sbp$timestamps,data$sbp$values)
        }
        
        if (!is.null(data$fluids)&length(data$fluids$timestamps>0)) {
            fluids = eval.sum.in.past(timestamps,data$fluids$timestamps,data$fluids$values,hours(1))
        }
        
        if (!is.null(data$urine)) {
            urine = eval.sum.in.past(timestamps,data$urine$timestamps,data$urine$values,hours(1))
        }
        
        if (!is.null(data$cvp)) {
            cvp = eval.carry.forward(timestamps,data$cvp$timestamps,data$cvp$values)
        }
        
        if (!is.null(data$lactate)) {
            lact = eval.carry.forward(timestamps,data$lactate$timestamps,data$lactate$values)
        }
        
        current.sirs = cbind(temp < 36 | temp > 38, hr>90, resp>20|paco2<32, wbc<4|wbc>12)
        current.sirs[is.na(current.sirs)] = F
        
        hypotension = sbp < 90
        hypotension[is.na(hypotension)] = F
        
        fluid.resuscitation = cvp > 8 | urine/weight > 0.5 | fluids/weight > 30
        fluid.resuscitation[is.na(fluid.resuscitation)] = F
        
        lactic.acidosis = lact > 2
        lactic.acidosis[is.na(lactic.acidosis)] = F
        
        sirs[[i]] = rowSums(current.sirs,na.rm=T) >= 2
        severe[[i]] = sirs[[i]] & (hypotension | lactic.acidosis)
        shock[[i]] = severe[[i]] & fluid.resuscitation & hypotension
    }
}

# Generate sepsis-2 labels
sepsis2.labels = mapply(function(a,b,c) {
    result = rep(0,length(a))
    result[a] = 1
    result[b] = 2
    result[c] = 3
    return(result)
},sirs,severe,shock)

save(sepsis2.labels,sepsis2.timestamps,sirs,severe,shock,file="sirs.rdata")
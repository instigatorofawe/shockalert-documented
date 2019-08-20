rm(list=ls())

library(xgboost)
library(glmnet)
library(pracma)
library(tictoc)
library(ROCR)
library(parallel)
library(lubridate)
library(ggplot2)

load("results/concomitant.combined.results2.rdata")
load("test.tables.concomitant.rdata")

load("mimic3.reference.data2.rdata")

a0 = do.call(rbind,nonsepsis.data)
a1 = do.call(rbind,nonshock.data)
a2 = do.call(rbind,preshock.data)
mimic.x = as.matrix(rbind(a0,a1,a2))
mimic.y = c(rep(0,dim(a0)[1]+dim(a1)[1]),rep(1,dim(a2)[1]))

sofa.scores = readRDS("processed/sofa_scores.rds")
clinical.data = readRDS("clinical.data.mimic.rds")
icustays = readRDS("icustays.rds")

clinical.icustay.ids = sapply(clinical.data, function(x) x$icustay.id)
clinical.subject.ids = sapply(clinical.icustay.ids,function(x) icustays$subject_id[which(icustays$icustay_id==x)])

is.adult = readRDS("is.adult.rds")
has.matched = readRDS("has.matched.rds")
icd9.infection.icustays = readRDS("icd9.infection.icustays.rds")
icd9.infection.subjects = readRDS("icd9.infection.subjects.rds")
load("infection.antibiotics.cultures.rdata")

has.infection.icd9 = is.element(clinical.icustay.ids, icd9.infection.icustays)
has.infection.abx = is.element(clinical.icustay.ids, infection.abx.icustays)
has.infection.cultures = is.element(clinical.icustay.ids, infection.culture.icustays)

has.infection = is.adult&has.infection.abx&has.infection.cultures

sepsis.labels = sapply(sofa.scores, function(x) rowSums(x[2:7])>=2)
has.sepsis = sapply(sepsis.labels, any)

shock.labels = mapply(function(x,y) {
    result=x&y$lactate&y$vasopressors
    result[is.na(result)] = F
    return(result)
}, sepsis.labels, sofa.scores)

has.shock = sapply(shock.labels, function(x) any(x,na.rm=T))

source("functions/eval_carry_forward.R")
source("functions/eval_interval.R")
source("functions/eval_max_in_past_2.R")
source("functions/eval_sum_in_past.R")
source("functions/eval_table_with_sofa_2.R")
source("functions/generate_table_with_sofa_timestamps_2.R")
source("functions/eval_early_prediction_premade_rf.R")
source("functions/eval_early_prediction_premade_glm.R")
source("functions/eval_early_prediction_timestamps_glm.R")
source("functions/eval_table_with_sofa_timestamps_history.R")


###
model.index = 10

roc.curve = performance(preds.glm[[model.index]],"tpr","fpr")
losses = mapply(function(x,y) sqrt(x^2+(1-y)^2), roc.curve@x.values[[1]], roc.curve@y.values[[1]])

loss.index = which.min(losses)
threshold = roc.curve@alpha.values[[1]][loss.index]

index = 219
###

labels = rep(0,length(sepsis.labels[[index]]))
labels[sepsis.labels[[index]]] = 1
labels[shock.labels[[index]]] = 2

timestamps = sofa.scores[[index]]$timestamps
timestamps = as.duration(timestamps-timestamps[1])/dhours(1)

shock.index = min(which(shock.labels[[index]]))

table = eval.table.with.sofa(sofa.scores[[index]]$timestamps,clinical.data[[index]])
for (i in 1:dim(table)[2]) {
    table[is.na(table[,i]),i] = means.all[[model.index]][i]
}

shock.time = timestamps[shock.index]

risk.score = predict(models.xgb[[model.index]],as.matrix(table))

detection.index = min(which(risk.score>=threshold))

data = data.frame(t=timestamps,risk=c(risk.score),z=labels)

png("figures/1a.png",width=800,height=600)
ggplot(data,aes(x=t,y=risk))+geom_line(size=1)+xlim(0,shock.time+10)+ylim(0,1.3)+
    geom_hline(yintercept=threshold,color="red",size=1)+
    geom_vline(xintercept=shock.time)+geom_vline(xintercept=timestamps[detection.index])+
    xlab("Time (hours)")+ylab("Risk Score Z(t)")+
    theme(axis.text=element_text(size=20),
          axis.title=element_text(size=24))
dev.off()
####

index = 8

labels = rep(0,length(sepsis.labels[[index]]))
labels[sepsis.labels[[index]]] = 1
labels[shock.labels[[index]]] = 2

timestamps = sofa.scores[[index]]$timestamps
timestamps = as.duration(timestamps-timestamps[1])/dhours(1)

shock.index = min(which(shock.labels[[index]]))

table = eval.table.with.sofa(sofa.scores[[index]]$timestamps,clinical.data[[index]])
for (i in 1:dim(table)[2]) {
    table[is.na(table[,i]),i] = means.all[[model.index]][i]
}

shock.time = timestamps[shock.index]

risk.score = predict(models.glm[[model.index]],as.matrix(table),s=models.glm[[model.index]]$lambda.min)

data = data.frame(t=timestamps,risk=c(risk.score),z=labels)

png("figures/1b.png",width=800,height=600)
ggplot(data,aes(x=t,y=risk))+geom_line(size=1)+ylim(0,1.3)+geom_hline(yintercept=threshold,color="red",size=1)+
    xlab("Time (hours)")+ylab("Risk Score Z(t)")+
    theme(axis.text=element_text(size=20),
          axis.title=element_text(size=24))
dev.off()

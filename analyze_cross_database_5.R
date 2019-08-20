rm(list=ls())

library(xgboost)
library(glmnet)
library(pracma)
library(tictoc)
library(ROCR)
library(parallel)

load("mimic3.reference.data2.rdata")

# Generate training data

a0 = do.call(rbind,nonsepsis.data)
a1 = do.call(rbind,nonshock.data)
a2 = do.call(rbind,preshock.data)
mimic.x = as.matrix(rbind(a0,a1,a2))
mimic.y = c(rep(0,dim(a0)[1]+dim(a1)[1]),rep(1,dim(a2)[1]))
mimic.means = colMeans(mimic.x,na.rm=T)

for (i in 1:dim(mimic.x)[2]) {
    mimic.x[is.na(mimic.x[,i]),i] = mimic.means[i]
}

tic("mimic.model.xgb")
mimic.model.xgb = xgboost(mimic.x, mimic.y, nrounds=25, objective="binary:logistic")
toc()

tic("mimic.model.glm")
mimic.model.glm = cv.glmnet(mimic.x, mimic.y, family="binomial")
toc()

load("eicu.test.rdata")

eicu.clinical.data = readRDS("eicu/clinical_data_icd9_sofa_vent.rds")
eicu.sofa.scores = readRDS("eicu/sofa_scores.rds")


lengths = sapply(eicu.sofa.scores, function(x) length(x$timestamps))
eicu.sepsis.labels = sapply(eicu.sofa.scores[lengths>0], function(x) rowSums(x[2:7])>=2)
eicu.has.sepsis = sapply(eicu.sepsis.labels, any)

# Determine shock onsets
eicu.shock.labels = mapply(function(x,y) x&y$lactate&y$vasopressors, eicu.sepsis.labels, eicu.sofa.scores[lengths>0])
eicu.has.shock = sapply(eicu.shock.labels, function(x) any(x,na.rm=T)) #& has.dx[lengths>0]
eicu.shock.onsets = mapply(function(x,y) min(x$timestamps[y],na.rm=T),eicu.sofa.scores[lengths>0][eicu.has.shock],eicu.shock.labels[eicu.has.shock])


source("eicu_functions/generate_sampling_rate_table.R")
source("eicu_functions/eval_carry_forward.R")
source("eicu_functions/eval_interval.R")
source("eicu_functions/eval_max_in_past_2.R")
source("eicu_functions/eval_sum_in_past.R")
source("eicu_functions/eval_early_prediction_timestamps_rf.R")
source("eicu_functions/eval_early_prediction_timestamps_glm.R")
source("eicu_functions/eval_table_with_sofa_2.R")
source("eicu_functions/generate_table_with_sofa_timestamps.R")
source("functions/eval_early_prediction_premade_glm.R")
source("functions/eval_early_prediction_premade_rf.R")

lengths = sapply(eicu.sofa.scores, function(x) length(x$timestamps))

tic("Early prediction, glm")
nonsepsis.predictions = lapply(eicu.nonsepsis.data, function(x) eval.early.prediction.premade.glm(as.matrix(x),mimic.means,mimic.model.glm))
nonshock.predictions = lapply(eicu.nonshock.data, function(x) eval.early.prediction.premade.glm(as.matrix(x),mimic.means,mimic.model.glm))
preshock.predictions = lapply(eicu.preshock.data, function(x) eval.early.prediction.premade.glm(as.matrix(x),mimic.means,mimic.model.glm))
toc()

nonsepsis.maxes = sapply(nonsepsis.predictions, max)
nonshock.maxes = sapply(nonshock.predictions, max)
shock.maxes = sapply(preshock.predictions, max)

pred = prediction(c(nonsepsis.maxes,nonshock.maxes,shock.maxes),c(rep(0,length(nonsepsis.maxes)+length(nonshock.maxes)),rep(1,length(shock.maxes))))
auc.glm = performance(pred,"auc")
roc.curve.glm = performance(pred,"tpr","fpr")
ppv.curve.glm = performance(pred,"ppv","sens")
losses = mapply(function(x,y) sqrt(x^2+(1-y)^2), roc.curve.glm@x.values[[1]], roc.curve.glm@y.values[[1]])
index = which.min(losses)
threshold = roc.curve.glm@alpha.values[[1]][index]

has.detection = shock.maxes>=threshold
ewt.glm.external = mapply(function(a,b,c) {
    c-a$timestamps[which.min(b>=threshold)]
}, eicu.sofa.scores[lengths>0][eicu.has.shock][has.detection], preshock.predictions[has.detection], eicu.shock.onsets[has.detection])


auc.glm.external = auc.glm@y.values[[1]]
sens.glm.external = roc.curve.glm@y.values[[1]][index]
spec.glm.external = 1-roc.curve.glm@x.values[[1]][index]
ppv.glm.external = ppv.curve.glm@y.values[[1]][index]


tic("Early prediction, xgb")
nonsepsis.predictions = lapply(eicu.nonsepsis.data, function(x) eval.early.prediction.premade.rf(as.matrix(x),mimic.means,mimic.model.xgb))
nonshock.predictions = lapply(eicu.nonshock.data, function(x) eval.early.prediction.premade.rf(as.matrix(x),mimic.means,mimic.model.xgb))
preshock.predictions = lapply(eicu.preshock.data, function(x) eval.early.prediction.premade.rf(as.matrix(x),mimic.means,mimic.model.xgb))
toc()

nonsepsis.maxes = sapply(nonsepsis.predictions, max)
nonshock.maxes = sapply(nonshock.predictions, max)
shock.maxes = sapply(preshock.predictions, max)

pred = prediction(c(nonsepsis.maxes,nonshock.maxes,shock.maxes),c(rep(0,length(nonsepsis.maxes)+length(nonshock.maxes)),rep(1,length(shock.maxes))))
auc.xgb = performance(pred,"auc")
roc.curve.xgb = performance(pred,"tpr","fpr")
ppv.curve.xgb = performance(pred,"ppv","sens")
losses = mapply(function(x,y) sqrt(x^2+(1-y)^2), roc.curve.xgb@x.values[[1]], roc.curve.xgb@y.values[[1]])
index = which.min(losses)
threshold = roc.curve.xgb@alpha.values[[1]][index]

has.detection = shock.maxes>=threshold
ewt.xgb.external = mapply(function(a,b,c) {
    c-a$timestamps[which.min(b>=threshold)]
}, eicu.sofa.scores[lengths>0][eicu.has.shock][has.detection], preshock.predictions[has.detection], eicu.shock.onsets[has.detection])

auc.xgb.external = auc.xgb@y.values[[1]]
sens.xgb.external = roc.curve.xgb@y.values[[1]][index]
spec.xgb.external = 1-roc.curve.xgb@x.values[[1]][index]
ppv.xgb.external = ppv.curve.xgb@y.values[[1]][index]

par(col="black")
plot(roc.curve.glm)
par(col="red")
plot(roc.curve.xgb,add=T)

par(col="black")
plot(ppv.curve.glm)
par(col="red")
plot(ppv.curve.xgb,add=T)

save(auc.glm.external,sens.glm.external,spec.glm.external,ppv.glm.external,ewt.glm.external,
     auc.xgb.external,sens.xgb.external,spec.xgb.external,ppv.xgb.external,ewt.xgb.external,
     file="results/external.xgb.glm5.rdata")
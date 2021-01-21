rm(list=ls())

library(parallel)
library(glmnet)
library(survival)
library(ROCR)
library(lubridate)
library(pracma)
library(tictoc)
library(tensorflow)
library(keras)
library(abind)

source("src/R/functions/mimic/generate_sampling_rate_table.R")
source("src/R/functions/mimic/eval_carry_forward.R")
source("src/R/functions/mimic/eval_interval.R")
source("src/R/functions/mimic/eval_max_in_past_2.R")
source("src/R/functions/mimic/eval_sum_in_past.R")
source("src/R/functions/mimic/eval_early_prediction_timestamps_glm.R")
source("src/R/functions/mimic/eval_early_prediction_timestamps_history.R")
source("src/R/functions/mimic/eval_table_with_sofa.R")
source("src/R/functions/mimic/eval_table_with_sofa_timestamps_history.R")
source("src/R/functions/mimic/generate_table_with_sofa_timestamps_history_2.R")

# Compare infection criteria across GLM/Cox on MIMIC-3
is.adult = readRDS("data/mimic/is.adult.rds")
icd9.infection.icustays = readRDS("data/mimic/icd9.infection.icustays.rds")
icd9.infection.subjects = readRDS("data/mimic/icd9.infection.subjects.rds")
load("data/mimic/infection.antibiotics.cultures.rdata")

sofa.scores = readRDS("data/mimic/processed/sofa_scores.rds")
clinical.data = readRDS("data/mimic/clinical.data.mimic.rds")
icustays = readRDS("data/mimic/icustays.rds")

clinical.icustay.ids = sapply(clinical.data, function(x) x$icustay.id)
clinical.subject.ids = sapply(clinical.icustay.ids,function(x) icustays$subject_id[which(icustays$icustay_id==x)])

has.infection.icd9 = is.element(clinical.icustay.ids, icd9.infection.icustays)
has.infection.abx = is.element(clinical.icustay.ids, infection.abx.icustays)
has.infection.cultures = is.element(clinical.icustay.ids, infection.culture.icustays)

###
# ICD9
# Generate labels
has.infection = has.infection.icd9&is.adult
sepsis.labels = sapply(sofa.scores[has.infection], function(x) rowSums(x[2:7])>=2)
has.sepsis = sapply(sepsis.labels, any)

shock.labels = mapply(function(x,y) x&y$lactate&y$vasopressors, sepsis.labels, sofa.scores[has.infection])
has.shock = sapply(shock.labels, function(x) any(x,na.rm=T))
shock.onsets = as_datetime(mapply(function(x,y) min(x$timestamps[y],na.rm=T),sofa.scores[has.infection][has.shock],shock.labels[has.shock]),tz="GMT")

load("data/mimic/icd9.lstm.reference.dataset.rdata")

nonsepsis.sample = runif(n=length(nonsepsis.data))<0.7
nonshock.sample = runif(n=length(nonshock.data))<0.7
preshock.sample = runif(n=length(preshock.data))<0.7

x0 = abind(nonsepsis.data[nonsepsis.sample],along=1)
x1 = abind(nonshock.data[nonshock.sample],along=1)
x2 = abind(preshock.data[preshock.sample],along=1)


x = abind(x0,x1,x2,along=1)
y = c(rep(0,dim(x0)[1]+dim(x1)[1]),rep(1,dim(x2)[1]))

# Mean value imputation
means = array(NA,dim=c(dim(x)[2],dim(x)[3]))
for (i in 1:dim(x)[2]) {
    for (j in 1:dim(x)[3]) {
        means[i,j] = mean(x[,i,j],na.rm=T)
        x[is.na(x[,i,j]),i,j] = means[i,j]
    }
}

# Upsample to rebalance classes
resample = sample(which(y==1),sum(y==0),replace=T)
x0.new = x[y==0,,]
x1.new = x[resample,,]

x.new = abind(x0.new,x1.new,along=1)
y.new = c(rep(0,dim(x0.new)[1]),rep(1,dim(x1.new)[1]))
y.new.categorical = to_categorical(y.new)


# Train RNN
model = keras_model_sequential()

model %>%
    layer_gru(units = 16, activation = 'relu', input_shape = c(10,13), return_sequences = T) %>%
    layer_gru(units = 16, activation = 'relu', input_shape = c(10,13), return_sequences = T) %>%
    layer_gru(units = 16, activation = 'relu', input_shape = c(10,13)) %>%
    layer_dense(units = 2, activation = 'softmax')


model %>% compile(
    optimizer = 'rmsprop',
    loss = 'categorical_crossentropy',
    metrics = c('accuracy')
)

history <- model %>% fit(
    x.new, y.new.categorical, 
    epochs = 64, batch_size = 512, 
    validation_split = 0.2,
    callbacks = callback_model_checkpoint("checkpoints/checkpoint.final.gru3.icd9.{epoch:02d}-{val_loss:.2f}.h5",save_best_only=T)
)

#model = load_model_hdf5("checkpoints/checkpoint.2.concomitant.subset.lstm.35-0.20.h5")

# Load test tables
load("data/mimic/eicu.lstm.test.rdata")
source("src/R/functions/mimic/eval_early_prediction_premade_history_rf.R")

tic("nonsepsis predictions")
nonsepsis.predictions = sapply(nonsepsis.data, function(x) eval.early.prediction.premade.history.rf(x,means,model))
toc()

tic("nonshock predictions")
nonshock.predictions = sapply(nonshock.data, function(x) eval.early.prediction.premade.history.rf(x,means,model))
toc()

tic("preshock predictions")
preshock.predictions = sapply(preshock.data, function(x) eval.early.prediction.premade.history.rf(x,means,model))
toc()

nonsepsis.maxes = sapply(nonsepsis.predictions, function(x) max(x[,2]))
nonshock.maxes = sapply(nonshock.predictions, function(x) max(x[,2]))
shock.maxes = sapply(preshock.predictions, function(x) max(x[-dim(x)[1],2]))
shock.maxes = shock.maxes[!is.infinite(shock.maxes)]

pred = prediction(c(nonsepsis.maxes,nonshock.maxes,shock.maxes),c(rep(0,length(nonsepsis.maxes)+length(nonshock.maxes)),rep(1,length(shock.maxes))))
perf = performance(pred,"tpr","fpr")
losses = mapply(function(x,y) sqrt(x^2+(1-y)^2), perf@x.values[[1]], perf@y.values[[1]])
threshold = perf@alpha.values[[1]][which.min(losses)]

pred = prediction(c(nonsepsis.maxes,nonshock.maxes,shock.maxes),c(rep(0,length(nonsepsis.maxes)+length(nonshock.maxes)),rep(1,length(shock.maxes))))
auc = performance(pred,"auc")

fprintf("Early prediction: %f AUC\n", auc@y.values[[1]])
perf = performance(pred,"ppv","sens")

roc.curve = performance(pred,"tpr","fpr")
ppv.curve = performance(pred,"ppv","sens")
sens = sum(shock.maxes>=threshold)/length(shock.maxes)
spec = (sum(nonsepsis.maxes<threshold)+sum(nonshock.maxes<threshold))/(length(nonsepsis.maxes)+length(nonshock.maxes))
ppv = sum(shock.maxes>=threshold)/(sum(shock.maxes>=threshold)+sum(nonsepsis.maxes>=threshold)+sum(nonshock.maxes>=threshold))

# Fix EWT calculation

eicu.clinical.data = readRDS("data/eicu/clinical_data_icd9_sofa_vent.rds")
eicu.patient.result = readRDS("data/eicu/patient_data.rds")
eicu.sofa.scores = readRDS("data/eicu/sofa_scores.rds")

lengths = sapply(eicu.sofa.scores, function(x) length(x$timestamps))
eicu.sepsis.labels = sapply(eicu.sofa.scores[lengths>0], function(x) rowSums(x[2:7])>=2)
eicu.has.sepsis = sapply(eicu.sepsis.labels, any)

# Determine shock onsets
eicu.shock.labels = mapply(function(x,y) x&y$lactate&y$vasopressors, eicu.sepsis.labels, eicu.sofa.scores[lengths>0])
eicu.has.shock = sapply(eicu.shock.labels, function(x) any(x,na.rm=T)) #& has.dx[lengths>0]
eicu.shock.onsets = mapply(function(x,y) min(x$timestamps[y],na.rm=T),eicu.sofa.scores[lengths>0][eicu.has.shock],eicu.shock.labels[eicu.has.shock])


has.detection = shock.maxes>=threshold
early.pred.times = mapply(function(a,b,c) {
    c-a$timestamps[which.min(b[,2]>=threshold)]
}, eicu.sofa.scores[lengths>0][eicu.has.shock][has.detection], preshock.predictions[has.detection], eicu.shock.onsets[has.detection])


save(model,pred,auc,sens,spec,ppv,nonsepsis.sample,nonshock.sample,preshock.sample,file="results/icd9.cross.gru6.rdata")

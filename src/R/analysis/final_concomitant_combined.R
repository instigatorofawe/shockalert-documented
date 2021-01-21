#### PUBLICATION VERSION
rm(list=ls())

library(parallel)
library(glmnet)
library(xgboost)
library(survival)
library(ROCR)
library(lubridate)
library(pracma)
library(tictoc)

# Number of cores
num.cores = 4


fprintf("Started at: %s\n", Sys.time())

source("src/R/functions/mimic/generate_sampling_rate_table.R")
source("src/R/functions/mimic/eval_carry_forward.R")
source("src/R/functions/mimic/eval_interval.R")
source("src/R/functions/mimic/eval_max_in_past_2.R")
source("src/R/functions/mimic/eval_sum_in_past.R")
source("src/R/functions/mimic/eval_table_with_sofa_4.R")
source("src/R/functions/mimic/generate_table_with_sofa_timestamps_2.R")
source("src/R/functions/mimic/eval_early_prediction_premade_rf.R")
source("src/R/functions/mimic/eval_early_prediction_premade_glm.R")

# Compare infection criteria across GLM/Cox on MIMIC-3
is.adult = readRDS("data/mimic/is.adult.rds")
has.matched = readRDS("data/mimic/has.matched.rds")
icd9.infection.icustays = readRDS("data/mimic/icd9.infection.icustays.rds")
icd9.infection.subjects = readRDS("data/mimic/icd9.infection.subjects.rds")
load("data/mimic/infection.antibiotics.cultures.rdata")

sofa.scores = readRDS("data/mimic/sofa_scores.rds")
clinical.data = readRDS("data/mimic/clinical.data.mimic.rds")
icustays = readRDS("data/mimic/icustays.rds")

clinical.icustay.ids = sapply(clinical.data, function(x) x$icustay.id)
clinical.subject.ids = sapply(clinical.icustay.ids,function(x) icustays$subject_id[which(icustays$icustay_id==x)])

has.infection.icd9 = is.element(clinical.icustay.ids, icd9.infection.icustays)
has.infection.abx = is.element(clinical.icustay.ids, infection.abx.icustays)
has.infection.cultures = is.element(clinical.icustay.ids, infection.culture.icustays)

# Concomitant
has.infection = has.infection.abx&has.infection.cultures&is.adult
sepsis.labels = sapply(sofa.scores[has.infection], function(x) rowSums(x[2:7])>=2)
has.sepsis = sapply(sepsis.labels, any)

shock.labels = mapply(function(x,y) x&y$lactate&y$vasopressors, sepsis.labels, sofa.scores[has.infection])
has.shock = sapply(shock.labels, function(x) any(x,na.rm=T))
shock.onsets = as_datetime(mapply(function(x,y) min(x$timestamps[y],na.rm=T),sofa.scores[has.infection][has.shock],shock.labels[has.shock]),tz="GMT")

iterations = 25

models.glm = vector(mode="list",length=iterations)
preds.glm = vector(mode="list",length=iterations)
ewts.glm = vector(mode="list",length=iterations)
auc.glm = rep(NA,iterations)
sens.glm = rep(NA,iterations)
spec.glm = rep(NA,iterations)
ppv.glm = rep(NA,iterations)
ewt.glm = rep(NA,iterations) # Median ewt

models.xgb = vector(mode="list",length=iterations)
preds.xgb = vector(mode="list",length=iterations)
ewts.xgb = vector(mode="list",length=iterations)
auc.xgb = rep(NA,iterations)
sens.xgb = rep(NA,iterations)
spec.xgb = rep(NA,iterations)
ppv.xgb = rep(NA,iterations)
ewt.xgb = rep(NA,iterations) # Median ewt

models.cox = vector(mode="list",length=iterations)
preds.cox = vector(mode="list",length=iterations)
ewts.cox = vector(mode="list",length=iterations)
auc.cox = rep(NA,iterations)
sens.cox = rep(NA,iterations)
spec.cox = rep(NA,iterations)
ppv.cox = rep(NA,iterations)
ewt.cox = rep(NA,iterations) # Median ewt

means.all = vector(mode="list",length=iterations)

load("data/mimic/concomitant.sample.rdata")
#nonsepsis.sample = runif(n=sum(!has.sepsis))<0.7
#nonshock.sample = runif(n=sum(has.sepsis&!has.shock))<0.7
#preshock.sample = runif(n=sum(has.shock))<0.7

load("data/mimic/test.tables.concomitant.rdata")

nonsepsis.timestamps = lapply(sofa.scores[has.infection][!has.sepsis][!nonsepsis.sample], function(x) x$timestamps)
nonshock.timestamps = lapply(sofa.scores[has.infection][has.sepsis&!has.shock][!nonshock.sample], function(x) x$timestamps)
preshock.timestamps = lapply(1:sum(!preshock.sample), function(x) sofa.scores[has.infection][has.shock][!preshock.sample][[x]]$timestamps[sofa.scores[has.infection][has.shock][!preshock.sample][[x]]$timestamps<=shock.onsets[!preshock.sample][x]])

for (k in 1:iterations) {
    fprintf("Iteration %d of %d...\n",k,iterations)
    tic("Iteration time")

    # Generate training data 
    # Runtime : 577 seconds, ~10 minutes
    #num.cores = detectCores()
    fprintf("\tGenerating training data...\n")
    cluster = makeCluster(num.cores)
    clusterExport(cluster,c("generate.table.with.sofa.timestamps","eval.carry.forward","eval.sum.in.past","eval.max.in.past","eval.interval","generate.table.with.sofa.timestamps","sofa.scores","clinical.data","shock.onsets","lengths","has.sepsis","has.shock","has.infection","nonsepsis.sample","nonshock.sample","preshock.sample"))
    clusterEvalQ(cluster,library(lubridate))
    tic("Generate data tables (parallel)")
    fprintf("\t\tGenerating nonsepsis training data...\n")
    nonsepsis.training.data = parLapply(cluster, 1:sum(nonsepsis.sample), function(x) generate.table.with.sofa.timestamps(min(sofa.scores[has.infection][!has.sepsis][nonsepsis.sample][[x]]$timestamps),max(sofa.scores[has.infection][!has.sepsis][nonsepsis.sample][[x]]$timestamps),100,clinical.data[has.infection][!has.sepsis][nonsepsis.sample][[x]]))
    fprintf("\t\tGenerating nonshock training data...\n")
    nonshock.training.data = parLapply(cluster, 1:sum(nonshock.sample), function(x) generate.table.with.sofa.timestamps(min(sofa.scores[has.infection][has.sepsis&!has.shock][nonshock.sample][[x]]$timestamps),max(sofa.scores[has.infection][has.sepsis&!has.shock][nonshock.sample][[x]]$timestamps),100,clinical.data[has.infection][has.sepsis&!has.shock][nonshock.sample][[x]]))
    fprintf("\t\tGenerating preshock training data...\n")
    preshock.training.data = parLapply(cluster, 1:sum(preshock.sample), function(x) generate.table.with.sofa.timestamps(shock.onsets[preshock.sample][x]-minutes(120),shock.onsets[preshock.sample][x]-minutes(60),100,clinical.data[has.infection][has.shock][preshock.sample][[x]]))
    fprintf("\t\tGenerating preshock (cox) training data...\n")
    preshock.cox.training.data = parLapply(cluster, 1:sum(preshock.sample), function(x) generate.table.with.sofa.timestamps(min(sofa.scores[has.infection][has.shock][preshock.sample][[x]]$timestamps),shock.onsets[preshock.sample][x],100,clinical.data[has.infection][has.shock][preshock.sample][[x]]))
    toc()
    stopCluster(cluster)
    
    fprintf("\tGenerating cox labels...\n")
    cluster = makeCluster(num.cores)
    clusterExport(cluster,c("sofa.scores","nonsepsis.training.data","nonshock.training.data","preshock.cox.training.data","shock.onsets","lengths","has.sepsis","has.shock","has.infection","nonsepsis.sample","nonshock.sample","preshock.sample"))
    clusterEvalQ(cluster,library(lubridate))
    tic("Generate cox labels")
    nonsepsis.labels.cox = parLapply(cluster, 1:sum(nonsepsis.sample), function(x) {
        cbind(as.duration(max(sofa.scores[has.infection][!has.sepsis][nonsepsis.sample][[x]]$timestamps)-nonsepsis.training.data[[x]]$timestamps)/dminutes(1),
              rep(0,length(nonsepsis.training.data[[x]]$timestamps)))
    })
    nonshock.labels.cox = parLapply(cluster, 1:sum(nonshock.sample), function(x) {
        cbind(as.duration(max(sofa.scores[has.infection][has.sepsis&!has.shock][nonshock.sample][[x]]$timestamps)-nonshock.training.data[[x]]$timestamps)/dminutes(1),
              rep(0,length(nonshock.training.data[[x]]$timestamps)))
    })
    preshock.labels.cox = parLapply(cluster, 1:sum(preshock.sample), function(x) {
        cbind(as.duration(shock.onsets[preshock.sample][x]-preshock.cox.training.data[[x]]$timestamps)/dminutes(1),
              rep(1,length(preshock.cox.training.data[[x]]$timestamps)))
    })
    toc()
    stopCluster(cluster)

    x0 = do.call(rbind,nonsepsis.training.data)[,-1]
    x1 = do.call(rbind,nonshock.training.data)[,-1]
    x2 = do.call(rbind,preshock.training.data)[,-1]
    
    x = as.matrix(rbind(x0,x1,x2))
    y = c(rep(0,dim(x0)[1]+dim(x1)[1]),rep(1,dim(x2)[1]))
    
    means = colMeans(x,na.rm=T)
    means.all[[k]] = means

    for (i in 1:dim(x)[2]) {
        x[is.na(x[,i]),i] = means[i]
    }

    tic("glmnet")
    model.glm = cv.glmnet(x,y,family="binomial")
    toc()

    tic("XGB")
    model.xgb = xgboost(x,y,nrounds=25,objective="binary:logistic")
    toc()

    x2 = do.call(rbind,preshock.cox.training.data)[,-1]

    y0 = do.call(rbind, nonsepsis.labels.cox)
    y1 = do.call(rbind, nonshock.labels.cox)
    y2 = do.call(rbind, preshock.labels.cox)

    y = rbind(y0,y1,y2)
    y[y[,1]==0,1] = 1
    y = Surv(y[,1],y[,2])


    x = as.matrix(rbind(x0,x1,x2))
    for (i in 1:dim(x)[2]) {
        x[is.na(x[,i]),i] = means[i]
    }

    tic("Fitting Cox model")
    model.cox = cv.glmnet(x,y,family="cox")
    toc()

    # Early prediction, GLM
    tic("Early prediction, glm")
    nonsepsis.predictions = lapply(nonsepsis.data[!nonsepsis.sample], function(x) eval.early.prediction.premade.glm(as.matrix(x),means,model.glm))
    nonshock.predictions = lapply(nonshock.data[!nonshock.sample], function(x) eval.early.prediction.premade.glm(as.matrix(x),means,model.glm))
    preshock.predictions = lapply(preshock.data[!preshock.sample], function(x) eval.early.prediction.premade.glm(as.matrix(x),means,model.glm))
    toc()

    nonsepsis.maxes = sapply(nonsepsis.predictions, max)
    nonshock.maxes = sapply(nonshock.predictions, max)
    shock.maxes = sapply(preshock.predictions, max)

    pred = prediction(c(nonsepsis.maxes,nonshock.maxes,shock.maxes),c(rep(0,length(nonsepsis.maxes)+length(nonshock.maxes)),rep(1,length(shock.maxes))))
    auc = performance(pred,"auc")
    roc.curve = performance(pred,"tpr","fpr")
    ppv.curve = performance(pred,"ppv","sens")
    losses = mapply(function(x,y) sqrt(x^2+(1-y)^2), roc.curve@x.values[[1]], roc.curve@y.values[[1]])
    index = which.min(losses)
    threshold = roc.curve@alpha.values[[1]][index]

    has.detection = shock.maxes>=threshold
    current.onsets = shock.onsets[!preshock.sample]
    current.ewts = mapply(function(a,b,c) as.duration(c-a[which.min(b>=threshold)])/dhours(1), preshock.timestamps[has.detection], preshock.predictions[has.detection], current.onsets[has.detection])

    models.glm[[k]] = model.glm
    preds.glm[[k]] = pred
    auc.glm[k] = auc@y.values[[1]]
    sens.glm[k] = roc.curve@y.values[[1]][index]
    spec.glm[k] = 1-roc.curve@x.values[[1]][index]
    ppv.glm[k] = ppv.curve@y.values[[1]][index]
    ewt.glm[k] = median(current.ewts)
    ewts.glm[[k]] = current.ewts

    # Early prediction, XGB
    tic("Early prediction, XGB")
    nonsepsis.predictions = lapply(nonsepsis.data[!nonsepsis.sample], function(x) eval.early.prediction.premade.rf(as.matrix(x),means,model.xgb))
    nonshock.predictions = lapply(nonshock.data[!nonshock.sample], function(x) eval.early.prediction.premade.rf(as.matrix(x),means,model.xgb))
    preshock.predictions = lapply(preshock.data[!preshock.sample], function(x) eval.early.prediction.premade.rf(as.matrix(x),means,model.xgb))
    toc()

    nonsepsis.maxes = sapply(nonsepsis.predictions, max)
    nonshock.maxes = sapply(nonshock.predictions, max)
    shock.maxes = sapply(preshock.predictions, max)

    pred = prediction(c(nonsepsis.maxes,nonshock.maxes,shock.maxes),c(rep(0,length(nonsepsis.maxes)+length(nonshock.maxes)),rep(1,length(shock.maxes))))
    auc = performance(pred,"auc")
    roc.curve = performance(pred,"tpr","fpr")
    ppv.curve = performance(pred,"ppv","sens")
    losses = mapply(function(x,y) sqrt(x^2+(1-y)^2), roc.curve@x.values[[1]], roc.curve@y.values[[1]])
    index = which.min(losses)
    threshold = roc.curve@alpha.values[[1]][index]

    has.detection = shock.maxes>=threshold
    current.onsets = shock.onsets[!preshock.sample]
    current.ewts = mapply(function(a,b,c) as.duration(c-a[which.min(b>=threshold)])/dhours(1), preshock.timestamps[has.detection], preshock.predictions[has.detection], current.onsets[has.detection])

    models.xgb[[k]] = model.xgb
    preds.xgb[[k]] = pred
    auc.xgb[k] = auc@y.values[[1]]
    sens.xgb[k] = roc.curve@y.values[[1]][index]
    spec.xgb[k] = 1-roc.curve@x.values[[1]][index]
    ppv.xgb[k] = ppv.curve@y.values[[1]][index]
    ewt.xgb[k] = median(current.ewts)
    ewts.xgb[[k]] = current.ewts

    # Early prediction, Cox
    tic("Early prediction, cox")
    nonsepsis.predictions = lapply(nonsepsis.data[!nonsepsis.sample], function(x) eval.early.prediction.premade.glm(as.matrix(x),means,model.cox))
    nonshock.predictions = lapply(nonshock.data[!nonshock.sample], function(x) eval.early.prediction.premade.glm(as.matrix(x),means,model.cox))
    preshock.predictions = lapply(preshock.data[!preshock.sample], function(x) eval.early.prediction.premade.glm(as.matrix(x),means,model.cox))
    toc()

    nonsepsis.maxes = sapply(nonsepsis.predictions, max)
    nonshock.maxes = sapply(nonshock.predictions, max)
    shock.maxes = sapply(preshock.predictions, max)

    pred = prediction(c(nonsepsis.maxes,nonshock.maxes,shock.maxes),c(rep(0,length(nonsepsis.maxes)+length(nonshock.maxes)),rep(1,length(shock.maxes))))
    auc = performance(pred,"auc")
    roc.curve = performance(pred,"tpr","fpr")
    ppv.curve = performance(pred,"ppv","sens")
    losses = mapply(function(x,y) sqrt(x^2+(1-y)^2), roc.curve@x.values[[1]], roc.curve@y.values[[1]])
    index = which.min(losses)
    threshold = roc.curve@alpha.values[[1]][index]

    has.detection = shock.maxes>=threshold
    current.onsets = shock.onsets[!preshock.sample]
    current.ewts = mapply(function(a,b,c) as.duration(c-a[which.min(b>=threshold)])/dhours(1), preshock.timestamps[has.detection], preshock.predictions[has.detection], current.onsets[has.detection])

    models.cox[[k]] = model.cox
    preds.cox[[k]] = pred
    auc.cox[k] = auc@y.values[[1]]
    sens.cox[k] = roc.curve@y.values[[1]][index]
    spec.cox[k] = 1-roc.curve@x.values[[1]][index]
    ppv.cox[k] = ppv.curve@y.values[[1]][index]
    ewt.cox[k] = median(current.ewts)
    ewts.cox[[k]] = current.ewts

}

save(models.glm,preds.glm,auc.glm,sens.glm,spec.glm,ppv.glm,ewt.glm,ewts.glm,
    models.xgb,preds.xgb,auc.xgb,sens.xgb,spec.xgb,ppv.xgb,ewt.xgb,ewts.xgb,
    models.cox,preds.cox,auc.cox,sens.cox,spec.cox,ppv.cox,ewt.cox,ewts.cox,
    means.all,
    file="results/concomitant.combined.results.rdata")

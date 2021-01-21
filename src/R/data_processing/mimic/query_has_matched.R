rm(list=ls())

data = read.delim("D:/Datasets/mimic3wdb-matched/RECORDS-numerics",header=F)
char.data = as.character(data$V1)

split.data = strsplit(char.data,"/")

matched.subjects = sapply(split.data, function(x) str2num(substr(x[2],2,7)))

saveRDS(matched.subjects,file="matched.subjects.rds")

clinical.data = readRDS("clinical.data.mimic.rds")
icustays = readRDS("icustays.rds")

clinical.subjects = sapply(clinical.data, function(x) icustays$subject_id[which(icustays$icustay_id==x$icustay.id)])

has.matched = is.element(clinical.subjects,matched.subjects)
saveRDS(has.matched,file="has.matched.rds")
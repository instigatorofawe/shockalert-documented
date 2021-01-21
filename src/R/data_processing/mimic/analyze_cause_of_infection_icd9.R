rm(list=ls())
icd9 = readRDS("icd9.rds")
icustays = readRDS("icustays.rds")

icd9.numeric = as.numeric(icd9$icd9_code)

icd9 = icd9[!is.na(icd9.numeric),]
icd9.numeric = icd9.numeric[!is.na(icd9.numeric)]

icd9.lengths = nchar(icd9$icd9_code)

icd9.numeric[icd9.lengths==4] = icd9.numeric[icd9.lengths==4]/10
icd9.numeric[icd9.lengths==5] = icd9.numeric[icd9.lengths==5]/100

has.infection.icd9 = sapply(icd9.numeric, function(x) any(is.element(floor(x), c(1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 21, 22, 23, 24, 25, 26, 27, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 90, 91, 92, 93, 94, 95, 96, 97, 98, 1, 00, 101, 102, 103, 104, 110, 111, 112, 114, 115, 116, 117, 118, 320, 322, 324, 325, 420, 421, 451, 461, 462, 463, 464, 465, 481, 482, 485, 486, 494, 510, 513, 540, 541, 542, 566, 567, 590, 597, 601, 614, 615, 616, 681, 682, 683, 686, 730))) | any(is.element(x, c(491.21, 562.01, 562.03, 562.11, 562.13, 569.5, 569.83, 572, 572.1, 575, 599, 711, 790.7, 996.6, 998.5, 999.3))))
icd9.infection.subjects = unique(icd9$subject_id[has.infection.icd9])
icd9.infection.icustays = unique(icustays$icustay_id[is.element(icustays$subject_id,icd9.infection.subjects)])

infection.codes.unique = unique(floor(icd9.numeric[has.infection.icd9]))
infection.codes.count = sapply(infection.codes.unique,function(x) sum(floor(icd9.numeric[has.infection.icd9])==x))

infection.codes.subject.count = sapply(infection.codes.unique, function(x) length(unique(icd9$subject_id[has.infection.icd9][floor(icd9.numeric[has.infection.icd9])==x])))

indices = order(infection.codes.subject.count,decreasing=T)

infection.codes.unique[indices[1:10]]
infection.codes.prevalences = infection.codes.subject.count[indices[1:10]]/length(unique(icd9$subject_id))

saveRDS(icd9.infection.subjects, file="icd9.infection.subjects.rds")
saveRDS(icd9.infection.icustays, file="icd9.infection.icustays.rds")

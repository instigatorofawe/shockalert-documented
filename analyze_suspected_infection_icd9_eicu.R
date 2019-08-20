rm(list=ls())
load("eicu/diagnosis_query.rdata")

library(tictoc)
library(parallel)

# Apply criteria in Derek Angus et al, Epidemiology of Severe Sepsis in the United States
has.infection.icd9 = sapply(codes, function(x) any(is.element(floor(x), c(1, 2, 3, 4, 5, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 21, 22, 23, 24, 25, 26, 27, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 90, 91, 92, 93, 94, 95, 96, 97, 98, 1, 00, 101, 102, 103, 104, 110, 111, 112, 114, 115, 116, 117, 118, 320, 322, 324, 325, 420, 421, 451, 461, 462, 463, 464, 465, 481, 482, 485, 486, 494, 510, 513, 540, 541, 542, 566, 567, 590, 597, 601, 614, 615, 616, 681, 682, 683, 686, 730))) | any(is.element(x, c(491.21, 562.01, 562.03, 562.11, 562.13, 569.5, 569.83, 572, 572.1, 575, 599, 711, 790.7, 996.6, 998.5, 999.3))))

saveRDS(has.infection.icd9, file="eicu/has_infection_icd9.rds")
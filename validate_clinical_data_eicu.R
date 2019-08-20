rm(list=ls())

# Ensure that all entries are correctly formatted
clinical.data = readRDS("eicu/clinical_data_dx.rds")

for (i in 1:length(clinical.data)) {
    fprintf("%d of %d...\n",i,length(clinical.data))
    lengths = sapply(clinical.data[[i]],length)
    indices = which(lengths==2)

    if (length(indices)>0) {
        for (j in 1:length(indices)) {
            if (!is.numeric(clinical.data[[i]][[indices[j]]]$values)) {
                clinical.data[[i]][[indices[j]]]$values = sapply(clinical.data[[i]][[indices[j]]]$values,mean)
            }
        }
    }
}

saveRDS(clinical.data, file="eicu/clinical_data_dx_cleaned.rds")
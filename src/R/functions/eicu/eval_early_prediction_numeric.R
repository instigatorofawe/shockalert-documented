# Evaluates value of z/p-hat over the length of the data
eval.early.prediction.numeric = function(model, data, numeric, means, min.time = NULL, max.time = NULL) {
    timestamps = c(unlist(sapply(data[sapply(data,length)==2], function(table) table$timestamps)),numeric$observationoffset)
    timestamps = sort(unique(timestamps[!is.null(timestamps)]))

    if (!is.null(min.time) & !is.null(max.time)) {
        timestamps = timestamps[timestamps>=min.time & timestamps<= max.time]
    }

    if (length(timestamps)==0) {
        return(NULL)
    }

    table = eval.table.with.sofa.numeric(timestamps,data,numeric)[,-1]
    #disp(table)

    for (i in 1:dim(table)[2]) {
        table[is.na(table[,i]),i] = means[i]
    }
    return(list(timestamps=timestamps,predictions=predict(model, newx=as.matrix(table), type="response")))
}
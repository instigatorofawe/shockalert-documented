# Evaluates value of z/p-hat over the length of the data
eval.early.prediction.coefficients = function(coefficients, data, means, stdevs, min.time = NULL, max.time = NULL) {
    timestamps = unlist(sapply(data[sapply(data,length)==2], function(table) table$timestamps))
    timestamps = sort(unique(timestamps[!is.null(timestamps)]))

    if (!is.null(min.time) & !is.null(max.time)) {
        timestamps = timestamps[timestamps>=min.time & timestamps<= max.time]
    }

    if (length(timestamps)==0) {
        return(NULL)
    }

    table = eval.table.with.sofa(timestamps,data)
    #disp(table)

    for (i in 1:dim(table)[2]) {
        table[is.na(table[,i]),i] = means[i]
        table[,i] = (table[,i]-means[i])/stdevs[i]
    }
    return(list(timestamps=timestamps,predictions=glmval(as.matrix(table), coefficients)))
}
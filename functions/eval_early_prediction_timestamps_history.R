# Evaluates value of z/p-hat over the length of the data
eval.early.prediction.timestamps.history = function(model, data, means, min.time = NULL, max.time = NULL, interval, history.n) {
    timestamps = unlist(sapply(data[sapply(data,length)==2], function(table) table$timestamps))    
    timestamps = as_datetime(sort(unique(timestamps[!is.null(timestamps)])),tz="GMT")

    if (!is.null(min.time) & !is.null(max.time)) {
        timestamps = timestamps[timestamps>=min.time & timestamps<= max.time]
    }

    if (length(timestamps)==0) {
        return(NULL)
    }

    table = eval.table.with.sofa.timestamps.history(timestamps,data,interval,history.n)
    #disp(table)
    #disp(dim(table))

    for (i in 1:dim(means)[1]) {
        for (j in 1:dim(means)[2]) {
            table[is.na(table[,i,j]),i,j] = means[i,j]
        }
    }
    return(list(timestamps=timestamps,predictions=predict(model, table)))
}
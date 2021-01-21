# Evaluates value of z/p-hat over the length of the data
eval.early.prediction.timestamps.glm = function(model, data, means, min.time = NULL, max.time = NULL) {
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
    }
    return(list(timestamps=timestamps,predictions=predict(model, as.matrix(table), s=model$lambda.min)))
}
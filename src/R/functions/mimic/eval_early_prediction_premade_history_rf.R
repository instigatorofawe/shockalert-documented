eval.early.prediction.premade.history.rf = function(data, means, model) {
    for (i in 1:dim(means)[1]) {
        for (j in 1:dim(means)[2]) {
            data[is.na(data[,i,j]),i,j] = means[i,j]
        }
    }
    return(predict(model,data))
}
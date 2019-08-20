eval.early.prediction.premade.glm = function(data, means, model) {
    for (i in 1:length(means)) {
        data[is.na(data[,i]),i] = means[i]
    }
    return(predict(model,data,s=model$lambda.min))
}
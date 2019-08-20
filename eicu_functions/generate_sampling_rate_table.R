generate.sampling.rate.table = function(data) {
    result = vector(mode="list",length=28)
    names(result) = names(data)
    result$subject.id = data$subject.id

    for (i in 2:length(data)) {
        if (length(data[[i]]$timestamps) < 2) {
            next
        } else {
            result[[i]] = list(timestamps = data[[i]]$timestamps[-1], values = data[[i]]$timestamps[-1] - data[[i]]$timestamps[-length(data[[i]]$timestamps)])
        }
    }

    return(result)
}
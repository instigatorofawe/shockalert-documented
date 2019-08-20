eval.max.in.past = function(eval.at.timestamps, timestamps, values, past, min.value = -Inf) {
    return(sapply(eval.at.timestamps, function(x) max(c(values[timestamps<=x&timestamps>=x-past],0))))
}
eval.max.in.past = function(timestamps, values, past) {
    return(sapply(timestamps, function(x) max(values[timestamps<=x&timestamps>=x-past])))
}
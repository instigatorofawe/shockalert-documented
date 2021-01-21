sum.in.past = function(timestamps, values, past) {
    return(sapply(timestamps, function(x) sum(values[timestamps<=x&timestamps>=x-past])))
}
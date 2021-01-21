eval.sum.in.past = function(eval.at.timestamps, timestamps, values, past) {
    return(sapply(eval.at.timestamps, function(x) sum(values[timestamps<=x&timestamps>=x-past])))
}
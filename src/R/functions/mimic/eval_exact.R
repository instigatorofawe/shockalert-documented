eval.exact = function(eval.at.timestamps, timestamps, values) {
    return(sapply(eval.at.timestamps, function(x) mean(values[timestamps==x],na.rm=T)))
}
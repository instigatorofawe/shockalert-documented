generate.table.with.sofa.timestamps.history = function(start, end, n, data, interval, history.n) {
    timestamps = sort(sample(start:end,n,replace=TRUE))
    return(eval.table.with.sofa.timestamps.history(timestamps,data,interval,history.n))
}
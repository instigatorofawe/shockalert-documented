generate.table.with.sofa.timestamps.numeric = function(start, end, n, data, numeric) {
    timestamps = sort(sample(start:end,n,replace=TRUE))
    return(eval.table.with.sofa.numeric(timestamps,data,numeric))
}
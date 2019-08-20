generate.table.with.sofa.comorbidities = function(start, end, n, data, comorbidities) {
    timestamps = as_datetime(sort(sample(start:end,n,replace=TRUE)),tz="GMT")
    return(eval.table.with.sofa.comorbidities(timestamps,data,comorbidities))
}
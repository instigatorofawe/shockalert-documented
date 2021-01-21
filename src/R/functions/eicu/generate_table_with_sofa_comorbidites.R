generate.table.with.sofa.comorbidities = function(start, end, n, data, comorbidities) {
    timestamps = sort(sample(start:end,n,replace=TRUE))
    return(eval.table.with.sofa.comorbidities(timestamps,data,comorbidities))
}
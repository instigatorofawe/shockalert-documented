merge.ts = function(timestamps1, values1, timestamps2, values2) {
    all.ts = c(timestamps1[!is.na(values1)], timestamps2[!is.na(values2)])
    all.values = c(values1, values2)

    unique.timestamps = sort(unique(all.ts))

    merged.values = sapply(unique.timestamps,function(x) mean(all.values[all.ts==x],na.rm=T))
    return(list(timestamps=unique.timestamps,values=merged.values))
}
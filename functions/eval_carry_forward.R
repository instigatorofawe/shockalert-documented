eval.carry.forward = function(eval.at.timestamps, timestamps, values, max.valid.duration = Inf) {
    # Error checking
    indices = !is.na(values)
    values = values[indices]
    timestamps = timestamps[indices]

    # ordering is unnecessary
    # ordering = order(timestamps)
    # timestamps = timestamps[ordering]
    # values = values[ordering]

    if (length(timestamps)==0) {
        return(rep(NA,length(eval.at.timestamps)))
    }
    # We carry forward observations for a maximum duration, if specified. If unspecified, then infinite
    results = rep(NA, length(eval.at.timestamps))
    indices = sapply(eval.at.timestamps, function(x) max(which(timestamps<=x)))
    distances = sapply(eval.at.timestamps, function(x) min((x-timestamps)[x-timestamps>=0]))
    results[distances<max.valid.duration] = values[indices[distances<max.valid.duration]]
    return(results)
}


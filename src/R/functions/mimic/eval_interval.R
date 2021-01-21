eval.interval = function(eval.at.timestamps, starts, stops, values=NULL) {
    # Start times and stop times may not be the same length
    # If an interval has no stop time, we assume it ends at the next start time
    # If there is no next interval, we assume it never ends
    return(sapply(eval.at.timestamps, function(x) {
        # If no values, we merely evaluate whether or not the timestamps are contained in an interval
        if (is.null(values)) {
            # Check if any start times are before our timestamp. If several, choose the largest.
            if (any(starts<=x)) {
                current.start = max(starts[starts<=x])
                if (any(stops>=current.start)) {
                    current.stop = min(stops[stops>=current.start])
                    if (current.stop>=x) {
                        return(TRUE)
                    } else {
                        return(FALSE)
                    }
                } else {
                    return(TRUE)
                }
            } else {
                return(FALSE)
            }
            # Check if there is any stop time before our timestamp, but after the chosen start time
            # If not, then valid.
        } else {
            # Otherwise, we have to determine which interval, and return the corresponding value
              if (any(starts<=x)) {
                current.start = max(starts[starts<=x])
                current.index = which(starts<=x)[which.max(starts[starts<=x])]
                if (any(stops>=current.start)) {
                    current.stop = min(stops[stops>=current.start])
                    if (current.stop>=x) {
                        return(values[current.index])
                    } else {
                        return(NA)
                    }
                } else {
                    return(values[current.index])
                }
            } else {
                return(NA)
            }
        }
    }))

    
}
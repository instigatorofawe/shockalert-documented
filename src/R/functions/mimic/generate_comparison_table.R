generate.comparison.table = function(ehr.timestamps, ehr.values, pts.timestamps, pts.values, threshold = 5) {

    # Get the closest
    results = array(NA,dim=c(length(ehr.timestamps),2))
    results[,1] = ehr.values

    results[,2] = sapply(ehr.timestamps, function(x) {
        distances = abs(pts.timestamps-x)
        if (min(distances)<=threshold) {
            return(pts.values[which.min(distances)])
        } else {
            return(NA)
        }
    })

    results = results[!apply(results,1,function(x) any(is.na(x))),,drop=F]

    return(results)

}
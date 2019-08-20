downsample = function(data, window.size) {
    if (is.vector(data)) {
        downsampled.data = rep(NA, ceil(length(data)/window.size))
        for (i in 1:length(downsampled.data)) {
            downsampled.data[i] = mean(na.omit(data[((i-1)*window.size+1):min((i*window.size),length(data))]))
        }
    } else {
        downsampled.data = array(NA, dim=c(ceil(dim(data)[1]/window.size), dim(data)[2]))
        for (i in 1:dim(downsampled.data)[1]) {
            downsampled.data[i,] = colMeans(data[((i-1)*window.size+1):min((i*window.size),dim(data)[1]),,drop=FALSE],na.rm=T)
        }
    }
    return(downsampled.data)
}
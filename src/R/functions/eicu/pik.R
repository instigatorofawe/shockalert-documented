pik = function(p, mu0, mu1, sigma0, sigma1, z, timestamps) {
    if (length(timestamps)<2) {
        return(p)
    }

    result = vector(mode="numeric",length=length(z))
    result[1] = dnorm(z[1],mean=mu1,sd=sigma1)*p/(dnorm(z[1],mean=mu1,sd=sigma1)*p+dnorm(z[1],mean=mu0,sd=sigma0)*(1-p))

    for (i in 2:length(result)) {
        prob = 1-(1-p)^(timestamps[i]-timestamps[i-1])
        lk = dnorm(z[i],mean=mu1,sd=sigma1)/dnorm(z[i],mean=mu0,sd=sigma0)
        result[i] = lk * (result[i-1] + (1 - result[i-1]) * prob) / ((1 - prob) * (1 - result[i-1]) + lk * (result[i-1] + (1 - result[i-1]) * prob));

    }
    return(result)
}
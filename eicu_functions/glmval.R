glmval = function(x, coefficients) {
    exponents = coefficients[1] + x %*% coefficients[-1]
    return(1/(1+exp(-1*exponents)))
}
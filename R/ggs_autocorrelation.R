#' Compute the autocorrelation of a single chain, for a specified amount of lags
#'
#' Internal function used by \code{\link{ggs_autocorrelation}}.
#'
#' @param x vector with a chain of simulated values
#' @param nLags maximum number of lags to take into account
#' @return a matrix with the autocorrelations of every chain
#' @export
#' @examples
#' # Calculate the autocorrelation of a simple vector
#' ac(cumsum(rnorm(10))/10, nLags=4)
ac <- function(x, nLags) {
  X <- matrix(NA, ncol=nLags, nrow=length(x))
  X[,1] <- x
  for (i in 2:nLags) {
    X[,i] <- c(rep(NA, i-1), x[1:(length(x)-i+1)])
  }
  X <- (cor(X, use="pairwise.complete.obs")[,1])
  return(X)
}

#' Plot an autocorrelation matrix
#'
#' @param D data frame whith the simulations
#' @param nLags integer indicating the number of lags of the autocorrelation plot
#' @return a ggplot object
#' @export
#' @examples
#' data(samples)
#' ggs_autocorrelation(ggs(S, parallel=FALSE))
ggs_autocorrelation <- function(D, nLags=50) {
  # I'm sure that this can be done directly through ddply, but have fight with
  # it for too many time, so it is somewhat dirty
  # Pass nLags as a variable of the dataframe, instead of a single number coming
  # from the arguments of the function.
  D.lags <- cbind(D, nLags=nLags)
  wc.ac <- ddply(D.lags, c("Parameter", "Chain"), summarise, 
    Autocorrelation=ac(value, nLags), 
    Lag=1:nLags,
    .parallel=attributes(D)$parallel)

  # Manage multiple chains
  if (attributes(D)$nChains <= 1) {
    f <- ggplot(wc.ac, aes(x=Lag, y=Autocorrelation)) + 
      geom_bar(stat="identity", position="identity") +
      facet_wrap(~ Parameter) + ylim(-1, 1)
  } else {
    f <- ggplot(wc.ac, aes(x=Lag, y=Autocorrelation, colour=as.factor(Chain), fill=as.factor(Chain))) + 
      geom_bar(stat="identity", position="identity") +
      facet_grid(Parameter ~ Chain) + ylim(-1, 1) +
      scale_fill_discrete(name="Chain") + scale_colour_discrete(name="Chain")
  }

 return(f)
}

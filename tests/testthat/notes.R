



# Mock iterative simulation
# @param output NULL=data.frame, or an output function
dosim <- function(niter=10, output=NULL) {
  output <- make_output(output)
  for(i in seq(1, niter)) {
    output(
      iter = i,
      a = seq(i, i+5),
      b = seq(i+1, i+6)
    )
  }
  output()
}

d <- dosim()
dosim(output=d)

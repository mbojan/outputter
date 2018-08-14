# Check an make extra columns

extracols <- function(...) {
  rval <- list(...)
  nams <- names(rval)
  if(any(nams == "")) stop("all arguments must be named")
  dups <- duplicated(nams)
  if(any(dups)) {
    stop(
      "duplicated argument names: ",
      paste(nams[dups], collapse=", ")
    )
  }
  lens <- vapply(rval, length, numeric(1))
  ok <- lens == 1
  if(any(!ok)) {
    stop(
      "lengths arguments which are longer than 1: ",
      paste(nams[!ok], lens[!ok], sep="=") %>%
        paste(collapse=", ")
    )
  }
  rval
}

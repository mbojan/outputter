#' Create output sink
#'
#' Function [make_output()] returns an output sink function of a type determined
#' by the class of the `output` argument. Output sink is a function that has a
#' single argument `...` through which one can pass multiple named arguments.
#' These arguments are expected to be vectors of the same length. Repeated calls
#' to an output sink write supplied data to a target, i.e. append a data frame,
#' write to a connection, or append a table in a database. Implemented methods
#' include:
#'
#' @param output an object determining the type of output sink to be created
#' @param ... additional arguments, see Details
#'
#' @details A call to [make_output()] returns a function, which we call "output
#'   sink". Output sink function has a signature `...` and expects **named**
#'   arguments to be vectors of the same length (shorter vectors will be
#'   recycled). Output sink is called for its side effect fo writing the
#'   supplied data somewhere.
#'
#'   Handling additional arguments passed through `...` to [make_output()] is
#'   method-dependent. If not stated otherwise below these arguments need to be
#'   named and can be used to insert extra columns which are
#'   "iteration-independent". See Examples.
#'
#' @return A function, say, `output` with signature `...` which will write data
#'   supplied in its arguments.
#'
#' @export

make_output <- function(output, ...) UseMethod("make_output")



#' @rdname make_output
#'
#' @description - Appending an existing data frame
#'
#' @details If `output` is a data frame then the calls to the output sink
#'   created will append that data frame. Appending uses [bind_rows()] which
#'   tries to match the columns by name. If output sink is called with an
#'   argument not used in previous calls then the result will have a new column
#'   and associated rows will have `NA`s.
#'
#' @export
#'
#' @examples
#' # --- Appending a data frame ---
#'
#' # Do note that the data frame does not have to be "empty"
#' out <- make_output(data.frame(a=numeric(0), b=numeric(0)))
#'
#' # A mock-up of iterative simulation
#' for( i in 1:5) {
#'   # Here some very intensive computations producing some `a` and `b`
#'   # and finally we call out() to write the results
#'   out(a=i+1, b=i-1)
#' }
#'
#' # Calling out() without arguments return the collected results
#' out()
#'
#'
#' # --- Appending a data frame with a static column ---
#'
#' out <- make_output(data.frame(a=numeric(0), b=numeric(0)), static=1)
#'
#' for( i in 1:5) {
#'   out(a=i+1, b=i-1)
#' }
#'
#' # Now the result has also column `static` always equal to 1
#' out()
#'
#'

make_output.data.frame <- function(output, ...) {
  results <- output
  extra <- extracols(...)
  function(...) {
    dots <- rlang::enquos(..., .named=TRUE)
    if(length(dots) == 0) {
      return(results)
    } else {
      dots <- c(dots, extra)
      d <- tibble::data_frame(!!!dots)
      results <<- dplyr::bind_rows(results, d)
    }
    results
  }
}

#' @rdname make_output
#'
#' @description - Appending a table in a database
#'
#' @details If `output` is an object inheriting from `tbl_dbi` then each call to
#' the output sink will append the table in the database the `tbl_dbi` object is
#' pointing to.
#'
#' @export
#'
#' @examples
#' # --- Appending a table in a database ---
#'
#' if(requireNamespace("RSQLite", quietly=TRUE)) {
#'   # In-memory SQLite database
#'   con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
#'   # An empty table in database
#'   DBI::dbWriteTable(con, "output", data.frame(a=numeric(0), b=numeric(0)))
#'   # A tbl_dbi table "pointing to" the database table
#'   d <- dplyr::tbl(con, "output")
#'
#'   out <- make_output(d)
#'
#'   # A mock-up of iterative simulation
#'   for( i in 1:5) {
#'     # Here some very intensive computations producing some `a` and `b`
#'     # and finally we call out() to write the results
#'     out(a=i+1, b=i-1)
#'   }
#'
#'   # Table has the results
#'   d
#'   # Calling out() without arguments return the tbl_dbi object
#'   out()
#' }
#'
#'
make_output.tbl_dbi <- function(output, ...) {
  requireNamespace("DBI")
  extras <- extracols(...)
  function(...) {
    dots <- rlang::enquos(..., .named=TRUE)
    if(length(dots) == 0) return(output)
    dots <- c(dots, extras)
    d <- tibble::data_frame(!!!dots)
    DBI::dbWriteTable(
      conn = output$src$con,
      name = output$ops$x,
      value = d,
      append = TRUE
    )
  }
}






#' @rdname make_output
#'
#' @description - Writing to a connection
#'
#' @details If `output` is a connection object then arguments in `...` are
#'   passed directly to [cat()] with argument `file` given the connection.
#'   Argument names are not included in the output nor checked. The order of the
#'   values "printed" by [cat()] is determined by the order of the arguments
#'   given to the output sink.
#'
#' @export
make_output.connection <- function(output, ...) {
  function(...) {
    cat(
      ...,
      "\n",
      file = output,
      append = TRUE
    )
  }
}





#' @rdname make_output
#'
#' @description - Creating a data frame "on the fly"
#'
#' @details If `output` is `NULL` then the result is an "blank" data frame
#'   output sink. The first call to the sink will instantiate the columns and
#'   subsequent calls will append it, as described above w.r. to the data frame
#'   method.
#'
#' @export
#'
#' @examples
#' # --- If `output` is NULL columns are created when out() is called ---
#'
#' out <- make_output(NULL)
#'
#' # A mock-up of iterative simulation
#' for( i in 1:5) {
#'   # Here some very intensive computations producing some `a` and `b`
#'   # and finally we call out() to write the results
#'   out(a=i+1, b=i-1)
#' }
#'
#' # A dataframe with columns `a` and `b`
#' out()
#'
#' # Calling out() with an argument to used earlier
#' for( i in 1:5) {
#'   out(c=i+10)
#' }
#'
#' # We have a new column with NAs in other columns in last 5 iterations
#' out()
#'
#'
make_output.default <- function(output, ...) {
  if(is.null(output)) {
    make_output.data.frame(output=NULL, ...)
  } else {
    stop("don't know how to handle class ", data.class(output))
  }
}


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
#' @param ... named arguments expected to be vectors. Shorter ones are recycled.
#'
#' @return A function, say, `output` with signature `...` which will write data
#' supplied in its arguments.
#'
#' @export

make_output <- function(output, ...) UseMethod("make_output")



#' @rdname make_output
#'
#' @description
#' - Appending an existing data frame
#'
#' @details If `output` is a data frame then the calls to the output sink
#' created will append that data frame.
#'
#' @export
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
#' @description
#' - Appending a table in a database
#'
#' @details
#' If `output` is an object inheriting from `tbl_dbi`...
#'
#' @export

make_output.tbl_dbi <- function(output, ...) {
  requireNamespace("DBI")
  function(...) {
    dots <- rlang::enquos(..., .named=TRUE)
    if(length(dots) == 0) return(output)
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
#'   passed to [cat()] with argument `file` given the connection. Argument names
#'   are not included in the output nor checked. The order of the values is
#'   determined by the order of the arguments.
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
#' @description
#' - Creating and appending a data frame
#'
#' @details If `output` is `NULL` then the result is an "blank" data frame
#'   output sink. The first call to the sink will instantiate the columns and
#'   subsequent calls will append it.
#'
#' @export
make_output.default <- function(output, ...) {
  if(is.null(output)) {
    make_output.data.frame(output=NULL, ...)
  } else {
    stop("don't know how to handle class ", data.class(output))
  }
}


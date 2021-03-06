% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/make_output.R
\name{make_output}
\alias{make_output}
\alias{make_output.data.frame}
\alias{make_output.tbl_dbi}
\alias{make_output.connection}
\alias{make_output.default}
\title{Create output sink}
\usage{
make_output(output, ...)

\method{make_output}{data.frame}(output, ...)

\method{make_output}{tbl_dbi}(output, ...)

\method{make_output}{connection}(output, ...)

\method{make_output}{default}(output, ...)
}
\arguments{
\item{output}{an object determining the type of output sink to be created}

\item{...}{additional arguments, see Details}
}
\value{
A function, say, \code{output} with signature \code{...} which will write data
supplied in its arguments.
}
\description{
Function \code{\link[=make_output]{make_output()}} returns an output sink function of a type determined
by the class of the \code{output} argument. Output sink is a function that has a
single argument \code{...} through which one can pass multiple named arguments.
These arguments are expected to be vectors of the same length. Repeated calls
to an output sink write supplied data to a target, i.e. append a data frame,
write to a connection, or append a table in a database. Implemented methods
include:

\itemize{
\item Appending an existing data frame
}

\itemize{
\item Appending a table in a database
}

\itemize{
\item Writing to a connection
}

\itemize{
\item Creating a data frame "on the fly"
}
}
\details{
A call to \code{\link[=make_output]{make_output()}} returns a function, which we call "output
sink". Output sink function has a signature \code{...} and expects \strong{named}
arguments to be vectors of the same length (shorter vectors will be
recycled). Output sink is called for its side effect fo writing the
supplied data somewhere.

Handling additional arguments passed through \code{...} to \code{\link[=make_output]{make_output()}} is
method-dependent. If not stated otherwise below these arguments need to be
named and can be used to insert extra columns which are
"iteration-independent". See Examples.

If \code{output} is a data frame then the calls to the output sink
created will append that data frame. Appending uses \code{\link[=bind_rows]{bind_rows()}} which
tries to match the columns by name. If output sink is called with an
argument not used in previous calls then the result will have a new column
and associated rows will have \code{NA}s.

If \code{output} is an object inheriting from \code{tbl_dbi} then each call to
the output sink will append the table in the database the \code{tbl_dbi} object is
pointing to.

If \code{output} is a connection object then arguments in \code{...} are
passed directly to \code{\link[=cat]{cat()}} with argument \code{file} given the connection.
Argument names are not included in the output nor checked. The order of the
values "printed" by \code{\link[=cat]{cat()}} is determined by the order of the arguments
given to the output sink.

If \code{output} is \code{NULL} then the result is an "blank" data frame
output sink. The first call to the sink will instantiate the columns and
subsequent calls will append it, as described above w.r. to the data frame
method.
}
\examples{
# --- Appending a data frame ---

# Do note that the data frame does not have to be "empty"
out <- make_output(data.frame(a=numeric(0), b=numeric(0)))

# A mock-up of iterative simulation
for( i in 1:5) {
  # Here some very intensive computations producing some `a` and `b`
  # and finally we call out() to write the results
  out(a=i+1, b=i-1)
}

# Calling out() without arguments return the collected results
out()


# --- Appending a data frame with a static column ---

out <- make_output(data.frame(a=numeric(0), b=numeric(0)), static=1)

for( i in 1:5) {
  out(a=i+1, b=i-1)
}

# Now the result has also column `static` always equal to 1
out()


# --- Appending a table in a database ---

if(requireNamespace("RSQLite", quietly=TRUE)) {
  # In-memory SQLite database
  con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  # An empty table in database
  DBI::dbWriteTable(con, "output", data.frame(a=numeric(0), b=numeric(0)))
  # A tbl_dbi table "pointing to" the database table
  d <- dplyr::tbl(con, "output")

  out <- make_output(d)

  # A mock-up of iterative simulation
  for( i in 1:5) {
    # Here some very intensive computations producing some `a` and `b`
    # and finally we call out() to write the results
    out(a=i+1, b=i-1)
  }

  # Table has the results
  d
  # Calling out() without arguments return the tbl_dbi object
  out()
}


# --- If `output` is NULL columns are created when out() is called ---

out <- make_output(NULL)

# A mock-up of iterative simulation
for( i in 1:5) {
  # Here some very intensive computations producing some `a` and `b`
  # and finally we call out() to write the results
  out(a=i+1, b=i-1)
}

# A dataframe with columns `a` and `b`
out()

# Calling out() with an argument to used earlier
for( i in 1:5) {
  out(c=i+10)
}

# We have a new column with NAs in other columns in last 5 iterations
out()


}

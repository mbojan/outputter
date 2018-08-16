
# outputter

The design goal of **outputter** is to provide a simple closure-based
syntax for saving/writing output from iterative simulations such that:

  - The simulation code can just call a function with data to be written
    as arguments
  - How the results are written/saved (e.g. a data frame object, a text
    file, a table in a database) can be decided outside of the actual
    simulation code.

See below for examples.

## Installation

Install development version from GitHub with

``` r
devtools::install_github("mbojan/outputter")
```

## Examples of use

A common problem when writing iterative simulations is implementing
several options of saving the results. Ideally one would like to be able
to “factor-out” the actual backend, i.e. how the results are saved,
outside of the simulation code. This is what **outputter** attempts to
achieve with a concept of “output sinks”.

### Basic use

### An implementation of a mock-up simulation function

Consider the following function performing a mock-up iterative
simulation:

``` r
run <- function(niter=5) {
  a <- 0
  b <- 5
  for( i in seq(1, niter) ) {
    # Here a lot of complex code producing output as two scalars `a` and `b`
    a <- a + i + 1
    b <- b + i - 1
  }
  list(a=a, b=b)
}
```

The function will go through the `for` loop and return the final values
of `a` and `b` as a list.

``` r
run()
#> $a
#> [1] 20
#> 
#> $b
#> [1] 15
```

What we would like instead is to:

  - Store the values of `a` and `b` from all simulation steps.
  - Have a choice how the values are stored.
  - Don’t have to modify the original simulation code with any
    output-processing code too much.

We can update `run()` from above by adding

1.  the `out` argument.
2.  a short code interpreting `out` argument that creates the output
    sink called `out()`.
3.  a call to `out()` that “spits” the results out from within the loop.
4.  a final call to `out()` that returns the results or some object that
    can be used to retrieve them.

The original simulation code (the body of the `for` loop) remains almost
untouched.

``` r
run <- function(niter=5, out=NULL) {
  # Create output sink function `out()` interpreting the `out` argument
  out <- switch(
    data.class(out),
    "function" = out, # `out` can be user-submitted f(...)
    outputter::make_output(out) # create a sink based on provided object
  )
  
  # The actual simulation code
  a <- 0
  b <- 5
  for( i in seq(1, niter) ) {
    # Here a lot of complex code producing output as two scalars `a` and `b`
    a <- a + i + 1
    b <- b - i - 1
    out(iteration=i, a=a, b=b)
  }
  
  out()
}
```

That solves the following usecases:

1.  Output as a data frame
    
    ``` r
    run()
    #> # A tibble: 5 x 3
    #>   iteration     a     b
    #>       <int> <dbl> <dbl>
    #> 1         1     2     3
    #> 2         2     5     0
    #> 3         3     9    -4
    #> 4         4    14    -9
    #> 5         5    20   -15
    ```

2.  Append an existing data frame
    
    ``` r
    d <- data.frame(a=-1, b=-1)
    run(out=d)
    #>    a   b iteration
    #> 1 -1  -1        NA
    #> 2  2   3         1
    #> 3  5   0         2
    #> 4  9  -4         3
    #> 5 14  -9         4
    #> 6 20 -15         5
    ```
    
    Notice a new column `iteration` has been added.

3.  Write to a connection
    
    ``` r
    # Setup the connection
    outfile <- tempfile()
    con <- file(outfile, open="w")
    
    # Run
    run(out=con)
    
    # Lines of output
    readLines(outfile)
    #> [1] "1 2 3 "    "2 5 0 "    "3 9 -4 "   "4 14 -9 "  "5 20 -15 " ""
    
    # Cleanup
    close(con)
    unlink(outfile)
    ```

4.  Append a table in a database (needs packages `DBI`, `RSQLite` and
    `dplyr`)
    
    ``` r
    # Set-up a table in an in-memory SQLite database
    con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
    # An empty table in database
    DBI::dbWriteTable(con, "output", data.frame(iteration=numeric(0), a=numeric(0), b=numeric(0)))
    # A tbl_dbi table "pointing to" the database table
    d <- dplyr::tbl(con, "output")
    
    # Run!
    run(out=d)   # returns a tbl_dbi object
    #> # Source:   table<output> [?? x 3]
    #> # Database: sqlite 3.22.0 [:memory:]
    #>   iteration     a     b
    #>       <dbl> <dbl> <dbl>
    #> 1         1     2     3
    #> 2         2     5     0
    #> 3         3     9    -4
    #> 4         4    14    -9
    #> 5         5    20   -15
    
    # The results can be collected from `d` too
    dplyr::collect(d)
    #> # A tibble: 5 x 3
    #>   iteration     a     b
    #>       <dbl> <dbl> <dbl>
    #> 1         1     2     3
    #> 2         2     5     0
    #> 3         3     9    -4
    #> 4         4    14    -9
    #> 5         5    20   -15
    
    # Cleanup
    DBI::dbDisconnect(con)
    rm(con, d)
    ```

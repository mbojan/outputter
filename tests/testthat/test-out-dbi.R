context("Testing DBI backend")

# Create in-memory SQLite with an empty table `output` with two numeric columns `a` and `b`
con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
DBI::dbWriteTable(con, "output", data.frame(a=numeric(0), b=numeric(0)))
d <- dplyr::tbl(con, "output")

# Function to truncate SQLite table
truncsqlite <- function(d) {
  res <- DBI::dbSendQuery(d$src$con, paste("DELETE FROM", d$ops$x))
  on.exit(DBI::dbClearResult(res))
  return(invisible(res))
}


test_that("writing to in-memory SQLite works", {
  out <- make_output(d)
  for(i in 1:5) {
    out(
      a=i,
      b=i+1
    )
  }
  r <- out()

  expect_equivalent(
    dplyr::collect(r),
    data.frame(
      a = 1:5 %>% as.numeric(),
      b = 2:6 %>% as.numeric()
    )
  )

  truncsqlite(r)
})




test_that("can include constant columns", {
  out <- make_output(d, run=1)
  for(i in 1:5) {
    out(
      a=i,
      b=i+1
    )
  }
  r <- out()
})







# Cleanup
DBI::dbDisconnect(con)
rm(d, truncsqlite)

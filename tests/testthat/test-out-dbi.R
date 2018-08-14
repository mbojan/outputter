context("Testing DBI backend")

# Create in-memory SQLite with an empty table `output` with two numeric columns `a` and `b`
con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
DBI::dbWriteTable(con, "output", data.frame(a=numeric(0), b=numeric(0)))
d <- dplyr::tbl(con, "output")



# Function to truncate SQLite tbl_dbi
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
  DBI::dbWriteTable(con, "output2", data.frame(a=numeric(0), b=numeric(0), run=numeric(0)))
  d3 <- dplyr::tbl(con, "output2")
  out <- make_output(d3, run=1)
  expect_silent(
    for(i in 1:5) {
      out(
        a=i,
        b=i+1
      )
    }
  )
  expect_silent(
    r <- out()
  )
  expect_equivalent(
    dplyr::collect(r),
    data.frame(
      a = 1:5 %>% as.numeric(),
      b = 2:6 %>% as.numeric(),
      run = 1
    )
  )
})







# Cleanup
DBI::dbDisconnect(con)
rm(d, truncsqlite)

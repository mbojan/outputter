context("Testing data frame sink")


test_that("repeated calls with scalars are silent and give proper output", {
  out <- make_output(
    data.frame(a=numeric(0), b=numeric(0))
    )
  expect_silent(
    for(i in 1:5) {
      out(a=i, b=-i)
    }
  )
  expect_silent(
    r <- out()
  )
  expect_equivalent(
    r,
    data.frame(a=1:5, b=seq(-1, -5))
  )
})






test_that("repeated calls with vectors work", {
  out <- make_output(
    data.frame(iter=numeric(0), b=numeric(0))
  )
  expect_silent(
    for(i in 1:5) {
      out(
        iter = i,
        b = 1:2
      )
    }
  )
  expect_silent(
    r <- out()
  )
  expect_equivalent(
    r,
    data.frame(
      iter = rep(1:5, each=2),
      b = rep(1:2, 5)
    )
  )
})




test_that("can use extra cols", {
  out <- make_output(
    data.frame(iter=numeric(0), b=numeric(0)),
    run = 1
  )
  expect_silent(
    for(i in 1:5) {
      out(
        iter = i,
        b = 1:2
      )
    }
  )
  expect_silent(
    r <- out()
  )
  expect_equivalent(
    r,
    data.frame(
      iter = rep(1:5, each=2),
      b = rep(1:2, 5),
      run = rep(1, 10)
    )
  )
})






test_that("can use extra cols with anonymous df", {
  out <- make_output(
    NULL,
    run = 1
  )
  expect_silent(
    for(i in 1:5) {
      out(
        iter = i,
        b = 1:2
      )
    }
  )
  expect_silent(
    r <- out()
  )
  expect_equivalent(
    r,
    data.frame(
      iter = rep(1:5, each=2),
      b = rep(1:2, 5),
      run = rep(1, 10)
    )
  )
})

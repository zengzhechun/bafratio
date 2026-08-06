test_that("bsr_* aliases are identical to ber_* functions", {
  expect_identical(bsr_estimate, ber_estimate)
  expect_identical(bsr_bootstrap, ber_bootstrap)
  expect_identical(bsr_classify, ber_classify)
  expect_identical(bsr_loo, ber_loo)
  expect_identical(bsr_diagnostics, ber_diagnostics)
  expect_identical(bsr_analyze, ber_analyze)
})

test_that("bsr alias produces the same numeric result", {
  a <- bsr_estimate(sim_est$logRr, sim_est$seLogRr,
                    sim_nc$logRr, sim_nc$seLogRr)
  b <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
                    sim_nc$logRr, sim_nc$seLogRr)
  expect_identical(a$ber, b$ber)
})

test_that("demo datasets are well-formed", {
  expect_equal(nrow(sim_nc), 12)
  expect_named(sim_nc, c("outcome", "logRr", "seLogRr"))
  expect_true(all(sim_nc$seLogRr > 0))
  expect_equal(nrow(sim_est), 1)
  expect_equal(sim_est$logRr, -0.184)
  expect_equal(sim_est$seLogRr, 0.045)
})

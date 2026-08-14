test_that("ber_estimate returns a BF in [0,1] consistent with BER", {
  est <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
                      sim_nc$logRr, sim_nc$seLogRr, ncNames = sim_nc$outcome)
  expect_true(est$bf > 0 && est$bf <= 1)
  expect_equal(est$bf, est$ber / (1 + est$ber), tolerance = 1e-10)
  expect_gt(est$bf, 0.5)
  expect_equal(est$classification, "bias-dominated")
})

test_that("ber_estimate returns BF = 1 when the calibrated effect is exactly 0", {
  # logRr exactly equal to the fitted mu_B forces log_rr_cal = 0
  ncLog <- c(-0.3, -0.2, -0.25, -0.18, -0.22)
  ncSe <- rep(0.05, 5)
  muHat <- EmpiricalCalibration::fitNull(ncLog, ncSe)[1]
  est <- ber_estimate(as.numeric(muHat), 0.05, ncLog, ncSe)
  expect_equal(est$bf, 1)
  expect_true(is.infinite(est$ber))
  expect_equal(ber_classify(est$ber), "bias-dominated")
})

test_that("ber_bootstrap returns bootstrap-median point estimates inside the CI", {
  b <- ber_bootstrap(sim_est$logRr, sim_est$seLogRr,
                     sim_nc$logRr, sim_nc$seLogRr, nBoot = 500, seed = 42)
  expect_true(b$ber_median >= b$ci_lo && b$ber_median <= b$ci_hi)
  expect_true(b$bf_median >= b$bf_ci_lo && b$bf_median <= b$bf_ci_hi)
  expect_equal(b$bf_ci_lo, b$ci_lo / (1 + b$ci_lo), tolerance = 1e-10)
  expect_equal(b$bf_ci_hi, b$ci_hi / (1 + b$ci_hi), tolerance = 1e-10)
  expect_equal(b$bf_median, b$ber_median / (1 + b$ber_median), tolerance = 1e-10)
  expect_equal(length(b$mu_draws), 500)
})

test_that("bf_classify reproduces the BER classification partition", {
  expect_equal(bf_classify(0.91), "bias-dominated")
  expect_equal(bf_classify(0.91, ciLo = 0.74, ciHi = 0.99), "bias-dominated")
  expect_equal(bf_classify(0.45, ciLo = 0.31, ciHi = 0.53), "competitive")
  expect_equal(bf_classify(0.20, ciLo = 0.10, ciHi = 0.30), "effect-dominated")
  expect_equal(bf_classify(0.5), "competitive")
  expect_equal(bf_classify(1 / 3), "competitive")
  expect_equal(bf_classify(NA_real_), "unclassifiable")
  # partition equivalence with ber_classify
  expect_equal(bf_classify(0.6), ber_classify(0.6 / 0.4))
  expect_equal(bf_classify(0.2), ber_classify(0.2 / 0.8))
})

test_that("bf_fieller returns region types and matches the demo scenario", {
  est <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
                      sim_nc$logRr, sim_nc$seLogRr)
  boot <- ber_bootstrap(sim_est$logRr, sim_est$seLogRr,
                        sim_nc$logRr, sim_nc$seLogRr, nBoot = 500, seed = 42)
  fset <- bf_fieller(est$mu_bias, stats::var(boot$mu_draws, na.rm = TRUE),
                     sim_est$logRr, sim_est$seLogRr)
  expect_true(fset$region %in% c("interior", "exterior", "empty", "whole"))
  if (fset$region %in% c("interior", "exterior")) {
    expect_true(is.finite(fset$lo) && is.finite(fset$hi))
    expect_lt(fset$lo, fset$hi)
  }
})

test_that("plot_bf_gauge builds for ber and biasratio objects", {
  est <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
                      sim_nc$logRr, sim_nc$seLogRr)
  fit <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
                     sim_nc$logRr, sim_nc$seLogRr, nBoot = 300, seed = 42)
  expect_s3_class(plot_bf_gauge(est), "ggplot")
  expect_s3_class(plot_bf_gauge(fit), "ggplot")
})

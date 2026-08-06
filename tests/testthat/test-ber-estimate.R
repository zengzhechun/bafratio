# 锚点数值来自 2026-08-06 的独立预演算（explore_demo_data.R），
# fitNull 为确定性 MLE，相同数据必然复现相同数值。

test_that("ber_estimate returns a well-formed ber object", {
  est <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
                      sim_nc$logRr, sim_nc$seLogRr, ncNames = sim_nc$outcome)
  expect_s3_class(est, "ber")
  expect_named(est, c("mu_bias", "sigma_bias", "log_rr_uncal", "se_log_rr",
                      "log_rr_cal", "se_log_rr_cal", "rr_uncal", "rr_cal",
                      "rr_bias", "ber", "p_uncal", "cal_p", "classification",
                      "nc_log_rr", "nc_se_log_rr", "nc_names", "null_fit"))
  expect_equal(est$nc_names, sim_nc$outcome)
})

test_that("ber_estimate reproduces the simulated-data anchors", {
  est <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
                      sim_nc$logRr, sim_nc$seLogRr)
  expect_equal(est$mu_bias, -0.2078, tolerance = 0.002)
  expect_equal(est$sigma_bias, 0.0268, tolerance = 0.002)
  expect_equal(est$ber, 8.73, tolerance = 0.05)
  expect_equal(est$cal_p, 0.6494, tolerance = 0.005)
  expect_equal(est$rr_uncal, 0.832, tolerance = 0.002)
  expect_equal(est$rr_cal, 1.024, tolerance = 0.005)
  expect_lt(est$p_uncal, 0.001)
  expect_equal(est$classification, "bias-dominated")
})

test_that("ber_estimate reproduces the sccs real-data anchors", {
  skip_if_not_installed("EmpiricalCalibration")
  data(sccs, package = "EmpiricalCalibration")
  nc <- sccs[sccs$groundTruth == 0, ]
  pc <- sccs[sccs$groundTruth == 1, ]
  est <- ber_estimate(pc$logRr, pc$seLogRr, nc$logRr, nc$seLogRr)
  expect_equal(est$mu_bias, 0.7922, tolerance = 0.002)
  expect_equal(est$ber, 13.31, tolerance = 0.3)
  expect_equal(est$cal_p, 0.8389, tolerance = 0.005)
  expect_equal(est$classification, "bias-dominated")
})

test_that("calibrated SE incorporates the systematic error variance", {
  est <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
                      sim_nc$logRr, sim_nc$seLogRr)
  expect_equal(est$se_log_rr_cal,
               sqrt(sim_est$seLogRr^2 + est$sigma_bias^2),
               tolerance = 1e-10)
})

test_that("ber_estimate handles the exact-zero calibrated effect edge case", {
  # 构造 logRr 恰等于 mu_B 的情形：BER 应为 Inf，分类偏倚主导
  est <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
                      sim_nc$logRr, sim_nc$seLogRr)
  est2 <- ber_estimate(est$mu_bias, sim_est$seLogRr,
                       sim_nc$logRr, sim_nc$seLogRr)
  expect_identical(est2$ber, Inf)
  expect_equal(est2$classification, "bias-dominated")
})

test_that("ber_estimate validates its inputs", {
  expect_error(ber_estimate(NA, 0.1, sim_nc$logRr, sim_nc$seLogRr),
               "single finite")
  expect_error(ber_estimate(0.1, -0.1, sim_nc$logRr, sim_nc$seLogRr),
               "positive")
  expect_error(ber_estimate(0.1, 0.1, sim_nc$logRr, sim_nc$seLogRr[-1]),
               "same length")
  expect_error(ber_estimate(0.1, 0.1, c(0.1, 0.2), c(0.1, 0.1)),
               "At least 3")
  expect_error(ber_estimate(0.1, 0.1, c(0.1, NA, 0.3), c(0.1, 0.1, 0.1)),
               "NA")
  expect_error(ber_estimate(0.1, 0.1, sim_nc$logRr, -sim_nc$seLogRr),
               "positive")
})

test_that("default NC names fall back to NC1..NCK or vector names", {
  est <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
                      sim_nc$logRr, sim_nc$seLogRr)
  expect_equal(est$nc_names, paste0("NC", 1:12))
  named <- stats::setNames(sim_nc$logRr, sim_nc$outcome)
  est2 <- ber_estimate(sim_est$logRr, sim_est$seLogRr, named, sim_nc$seLogRr)
  expect_equal(est2$nc_names, sim_nc$outcome)
})

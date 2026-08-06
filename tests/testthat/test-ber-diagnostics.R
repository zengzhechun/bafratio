test_that("standardized residuals use the marginal SD", {
  d <- ber_diagnostics(sim_nc$logRr, sim_nc$seLogRr, ncNames = sim_nc$outcome)
  expect_s3_class(d, "ber_diag")
  manual <- (sim_nc$logRr - d$mu) / sqrt(sim_nc$seLogRr^2 + d$sigma^2)
  expect_equal(d$std_residuals, manual, tolerance = 1e-12)
})

test_that("simulated-data diagnostics anchors hold", {
  d <- ber_diagnostics(sim_nc$logRr, sim_nc$seLogRr, ncNames = sim_nc$outcome)
  expect_equal(d$mu, -0.2078, tolerance = 0.002)
  expect_equal(d$shapiro_p, 0.637, tolerance = 0.05)
  # 最大标准化残差对应 BPH（冒烟测试实测值 1.35）
  expect_equal(d$max_resid_name, "Benign prostatic hyperplasia")
  expect_equal(abs(d$max_resid), 1.35, tolerance = 0.05)
  expect_true(d$shapiro_p >= 0 && d$shapiro_p <= 1)
})

test_that("qq data are sorted sample quantiles", {
  d <- ber_diagnostics(sim_nc$logRr, sim_nc$seLogRr)
  expect_equal(nrow(d$qq), 12)
  expect_true(all(diff(d$qq$sample) >= 0))
  expect_equal(d$qq$sample, sort(d$std_residuals))
})

test_that("ber_diagnostics validates inputs", {
  expect_error(ber_diagnostics(c(0.1, 0.2), c(0.1, 0.1)), ">= 3")
  expect_error(ber_diagnostics(c(0.1, NA, 0.3), c(0.1, 0.1, 0.1)), "finite")
})

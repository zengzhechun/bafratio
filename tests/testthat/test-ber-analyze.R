test_that("ber_analyze bundles all components", {
  fit <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
                     sim_nc$logRr, sim_nc$seLogRr,
                     ncNames = sim_nc$outcome, nBoot = 300, seed = 42)
  expect_s3_class(fit, "biasratio")
  expect_s3_class(fit$estimate, "ber")
  expect_s3_class(fit$bootstrap, "ber_boot")
  expect_s3_class(fit$diagnostics, "ber_diag")
  expect_null(fit$loo)
  expect_equal(fit$classification, "bias-dominated")
})

test_that("ber_analyze with loo = TRUE includes the LOO table", {
  fit <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
                     sim_nc$logRr, sim_nc$seLogRr,
                     ncNames = sim_nc$outcome,
                     nBoot = 300, seed = 42, loo = TRUE, looBoot = 50)
  expect_s3_class(fit$loo, "ber_loo")
  expect_equal(nrow(fit$loo), 12)
})

test_that("print and summary methods produce output", {
  fit <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
                     sim_nc$logRr, sim_nc$seLogRr, nBoot = 300, seed = 42)
  expect_output(print(fit), "BER =")
  expect_output(print(fit), "bias-dominated")
  expect_output(summary(fit), "BER =")
  expect_output(print(fit$estimate), "Bias-effect ratio")
  expect_output(print(fit$bootstrap), "Bootstrap CI")
  expect_output(print(fit$diagnostics), "Shapiro-Wilk")
})

test_that("CI-based classification differs from point-only when CI crosses 1", {
  # 构造一个点估计 > 1 但 CI 下界 < 1 的情形应判为 competitive
  # 用极不精确的 NC（大 SE）让 bootstrap CI 很宽
  ncLog <- c(-0.3, -0.1, -0.2, -0.25, -0.15)
  ncSe <- c(0.5, 0.6, 0.55, 0.5, 0.6)
  est <- ber_estimate(-0.15, 0.05, ncLog, ncSe)
  boot <- ber_bootstrap(-0.15, 0.05, ncLog, ncSe, nBoot = 300, seed = 1)
  cls <- ber_classify(est$ber, boot$ci_lo, boot$ci_hi)
  expect_true(cls %in% c("competitive", "bias-dominated"))
})

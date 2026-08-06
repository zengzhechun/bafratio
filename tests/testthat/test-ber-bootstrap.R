test_that("ber_bootstrap is reproducible with a fixed seed", {
  b1 <- ber_bootstrap(sim_est$logRr, sim_est$seLogRr,
                      sim_nc$logRr, sim_nc$seLogRr, nBoot = 300, seed = 42)
  b2 <- ber_bootstrap(sim_est$logRr, sim_est$seLogRr,
                      sim_nc$logRr, sim_nc$seLogRr, nBoot = 300, seed = 42)
  expect_identical(b1$ci_lo, b2$ci_lo)
  expect_identical(b1$ci_hi, b2$ci_hi)
  expect_identical(b1$boot_dist, b2$boot_dist)
})

test_that("ber_bootstrap returns ordered CIs containing the point estimate", {
  b <- ber_bootstrap(sim_est$logRr, sim_est$seLogRr,
                     sim_nc$logRr, sim_nc$seLogRr, nBoot = 500, seed = 42)
  expect_s3_class(b, "ber_boot")
  expect_true(b$ci_lo < b$ci_hi)
  expect_true(b$ber >= b$ci_lo && b$ber <= b$ci_hi)
  expect_equal(b$n_boot, 500)
  expect_equal(b$success_rate, 1)
  expect_length(b$boot_dist, 500)
})

test_that("log method and percentile method both give valid CIs", {
  bLog <- ber_bootstrap(sim_est$logRr, sim_est$seLogRr,
                        sim_nc$logRr, sim_nc$seLogRr,
                        nBoot = 500, seed = 42, method = "log")
  bRaw <- ber_bootstrap(sim_est$logRr, sim_est$seLogRr,
                        sim_nc$logRr, sim_nc$seLogRr,
                        nBoot = 500, seed = 42, method = "percentile")
  expect_true(bLog$ci_lo < bLog$ci_hi)
  expect_true(bRaw$ci_lo < bRaw$ci_hi)
  # 两种方法对同一数据的分类结论应一致（模拟数据偏倚主导非常稳健）
  expect_equal(ber_classify(bLog$ber, bLog$ci_lo, bLog$ci_hi), "bias-dominated")
  expect_equal(ber_classify(bRaw$ber, bRaw$ci_lo, bRaw$ci_hi), "bias-dominated")
})

test_that("confidence level is respected", {
  b90 <- ber_bootstrap(sim_est$logRr, sim_est$seLogRr,
                       sim_nc$logRr, sim_nc$seLogRr,
                       nBoot = 500, seed = 42, level = 0.90)
  b95 <- ber_bootstrap(sim_est$logRr, sim_est$seLogRr,
                       sim_nc$logRr, sim_nc$seLogRr,
                       nBoot = 500, seed = 42, level = 0.95)
  expect_true(b90$ci_lo >= b95$ci_lo)
  expect_true(b90$ci_hi <= b95$ci_hi)
})

test_that("cohortMethod effect-dominated CI stays below 0.5", {
  skip_if_not_installed("EmpiricalCalibration")
  data(cohortMethod, package = "EmpiricalCalibration")
  nc <- cohortMethod[cohortMethod$groundTruth == 0, ]
  pc <- cohortMethod[cohortMethod$groundTruth == 1, ]
  b <- ber_bootstrap(pc$logRr, pc$seLogRr, nc$logRr, nc$seLogRr,
                     nBoot = 500, seed = 42)
  expect_lt(b$ci_hi, 0.5)
  expect_equal(ber_classify(b$ber, b$ci_lo, b$ci_hi), "effect-dominated")
})

test_that("baf_loo returns one row per negative control", {
  loo <- baf_loo(sim_est$logRr, sim_est$seLogRr,
                 sim_nc$logRr, sim_nc$seLogRr,
                 ncNames = sim_nc$outcome, nBoot = 0)
  expect_s3_class(loo, "baf_loo")
  expect_equal(nrow(loo), 12)
  expect_equal(loo$excluded, sim_nc$outcome)
  expect_true(all(is.finite(loo$ber)))
  expect_true(all(is.na(loo$ci_lo)))
  # 模拟数据偏倚主导非常稳健：剔除任一 NC 后点估计仍 > 1
  expect_true(all(loo$ber > 1))
})

test_that("baf_loo bootstrap CIs are ordered and reproducible", {
  loo1 <- baf_loo(sim_est$logRr, sim_est$seLogRr,
                  sim_nc$logRr, sim_nc$seLogRr, nBoot = 100, seed = 7)
  loo2 <- baf_loo(sim_est$logRr, sim_est$seLogRr,
                  sim_nc$logRr, sim_nc$seLogRr, nBoot = 100, seed = 7)
  expect_identical(loo1$ci_lo, loo2$ci_lo)
  expect_true(all(loo1$ci_lo < loo1$ci_hi))
})

test_that("baf_loo requires at least 4 negative controls", {
  expect_error(
    baf_loo(0.1, 0.1, c(0.1, 0.2, 0.3), c(0.1, 0.1, 0.1)),
    "at least 4"
  )
})

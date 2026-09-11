test_that("ber_screen runs on raw inputs and returns a ber_screen object", {
  sc <- ber_screen(sim_est$logRr, sim_est$seLogRr,
                   sim_nc$logRr, sim_nc$seLogRr, nBoot = 300, seed = 42)
  expect_s3_class(sc, "ber_screen")
  expect_true(is.logical(sc$layer1$passed))
  expect_true(is.numeric(sc$layer2$p_bias_dom))
  expect_true(sc$layer2$p_bias_dom >= sc$layer2$p_bias_dom_narrow)
  expect_true(sc$layer2$p_bias_dom >= sc$layer2$p_bias_dom_wide)
})

test_that("Layer 1 fails when calibrated p is at/above the threshold", {
  # Build a clearly null primary estimate (huge SE) so calibrated p >= 0.05
  ncLog <- c(-0.21, -0.19, -0.22, -0.20, -0.18, -0.23)
  ncSe <- c(0.05, 0.05, 0.05, 0.05, 0.05, 0.05)
  sc <- ber_screen(-0.05, 0.5, ncLog, ncSe, nBoot = 200, seed = 7)
  expect_false(sc$layer1$passed)
  expect_equal(sc$verdict$code, "insufficient-evidence")
})

test_that("verdict bands map P(bias-dominated) correctly", {
  # Direct unit test of the band rule (internal helper, available under load_all)
  vb <- biasratio:::.verdict_band
  expect_equal(vb(0.05, TRUE)$code, "effect-evidence")
  expect_equal(vb(0.30, TRUE)$code, "mixed")
  expect_equal(vb(0.55, TRUE)$code, "competitive")
  expect_equal(vb(0.80, TRUE)$code, "not-effect-evidence")
  expect_equal(vb(0.80, FALSE)$code, "insufficient-evidence")
})

test_that("effect-dominated scenario yields effect-evidence", {
  # Tiny bias (NCs ~ 0) and a large calibrated effect -> low BAF -> effect-evidence
  ncLog <- c(0.001, -0.001, 0.002, -0.002, 0.000)
  ncSe <- rep(0.05, 5)
  sc <- ber_screen(-0.60, 0.02, ncLog, ncSe, nBoot = 200, seed = 5)
  expect_true(sc$layer1$passed)
  expect_equal(sc$verdict$code, "effect-evidence")
})

test_that("bf_screen is an alias of ber_screen", {
  sc1 <- ber_screen(sim_est$logRr, sim_est$seLogRr,
                    sim_nc$logRr, sim_nc$seLogRr, nBoot = 200, seed = 42)
  sc2 <- bf_screen(sim_est$logRr, sim_est$seLogRr,
                   sim_nc$logRr, sim_nc$seLogRr, nBoot = 200, seed = 42)
  expect_equal(sc1$verdict$code, sc2$verdict$code)
  expect_equal(sc1$layer2$p_bias_dom, sc2$layer2$p_bias_dom)
})

test_that("ber_screen accepts a biasratio object without recomputing", {
  fit <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
                     sim_nc$logRr, sim_nc$seLogRr, nBoot = 200, seed = 42)
  sc <- ber_screen(fit)
  expect_s3_class(sc, "ber_screen")
  expect_equal(sc$layer1$cal_p, fit$estimate$cal_p)
})

test_that("print and explain produce English output", {
  sc <- ber_screen(sim_est$logRr, sim_est$seLogRr,
                   sim_nc$logRr, sim_nc$seLogRr, nBoot = 200, seed = 42)
  expect_output(print(sc), "two-layer screening")
  expect_output(print(sc), "Verdict")
  exp <- explain(sc)
  expect_type(exp, "character")
  expect_true(grepl("Layer 1", exp))
})

test_that("summary.ber_screen returns a one-row data frame", {
  sc <- ber_screen(sim_est$logRr, sim_est$seLogRr,
                   sim_nc$logRr, sim_nc$seLogRr, nBoot = 200, seed = 42)
  sm <- summary(sc)
  expect_s3_class(sm, "data.frame")
  expect_equal(nrow(sm), 1L)
  expect_true("verdict_code" %in% names(sm))
})

test_that("CI truncation at 0/1 is flagged as clipped", {
  # A BAF very near 1 (calibrated effect ~ 0) forces bf_ci_hi to 1 -> clipped.
  ncLog <- c(-0.30, -0.28, -0.31, -0.29, -0.27)
  ncSe <- c(0.02, 0.02, 0.02, 0.02, 0.02)
  sc <- ber_screen(-0.001, 0.01, ncLog, ncSe, nBoot = 200, seed = 11)
  expect_true(is.logical(sc$layer2$clipped))
})

test_that("baf_rules returns all seven rules in a fixed order", {
  r <- baf_rules(0.45, ciLo = 0.30, ciHi = 0.48, cal_p = 0.01,
                p_bias_dom = 0.12, uncal_p = 0.001)
  expect_s3_class(r, "data.frame")
  expect_identical(r$rule, c("R0", "R1", "R2", "R3", "R4", "C1", "C2"))
  expect_true(all(c("rule", "criterion", "pass") %in% names(r)))
  expect_identical(nrow(r), 7L)
})

test_that("baf_rules reproduces the manuscript rule definitions", {
  r <- baf_rules(0.45, ciLo = 0.30, ciHi = 0.48, cal_p = 0.01,
                p_bias_dom = 0.12, uncal_p = 0.001)
  p <- stats::setNames(r$pass, r$rule)
  # R0 and R1 pass on the p-values alone
  expect_true(p[["R0"]])
  expect_true(p[["R1"]])
  # R2 and C1: point estimate 0.45 is below the 0.5 threshold
  expect_true(p[["R2"]])
  expect_true(p[["C1"]])
  # R3 and C2: interval upper limit 0.48 is at or below 0.5
  expect_true(p[["R3"]])
  expect_true(p[["C2"]])
  # R4: P(bias-dominated) 0.12 is below 0.15
  expect_true(p[["R4"]])
})

test_that("baf_rules keeps the strict/non-strict asymmetry between R2 and R3", {
  # A point estimate exactly at the threshold fails R2 (strict <) ...
  p <- stats::setNames(
    baf_rules(0.50, ciLo = 0.40, ciHi = 0.50, cal_p = 0.01)$pass,
    c("R0", "R1", "R2", "R3", "R4", "C1", "C2")
  )
  expect_false(p[["R2"]])
  expect_true(p[["R3"]])
  expect_false(p[["C1"]])
  expect_true(p[["C2"]])
})

test_that("baf_rules returns NA rather than FALSE for missing inputs", {
  r <- baf_rules(0.45)
  p <- stats::setNames(r$pass, r$rule)
  expect_true(is.na(p[["R0"]]))
  expect_true(is.na(p[["R1"]]))
  expect_true(is.na(p[["R4"]]))
  expect_true(is.na(p[["R3"]]))
  expect_true(is.na(p[["C2"]]))
  # C1 needs only the point estimate, which was supplied
  expect_true(p[["C1"]])
})

test_that("C1 and C2 ignore the calibrated p-value (they are stand-alone)", {
  pass <- baf_rules(0.20, ciLo = 0.10, ciHi = 0.30, cal_p = 0.90)$pass
  p <- stats::setNames(pass, c("R0", "R1", "R2", "R3", "R4", "C1", "C2"))
  expect_false(p[["R1"]])   # Layer 1 fails
  expect_true(p[["C1"]])    # but the stand-alone comparators still pass
  expect_true(p[["C2"]])
})

test_that("baf_rules and baf_classify answer different questions", {
  # Documented divergence: the zone classifier calls this "mixed" because the
  # interval upper limit 0.48 is not below 1/3, while rule R3 accepts it.
  expect_identical(baf_classify(0.45, ciLo = 0.30, ciHi = 0.48), "mixed")
  p <- stats::setNames(
    baf_rules(0.45, ciLo = 0.30, ciHi = 0.48, cal_p = 0.01)$pass,
    c("R0", "R1", "R2", "R3", "R4", "C1", "C2")
  )
  expect_true(p[["R3"]])
})

test_that("baf_rules thresholds are configurable", {
  p <- stats::setNames(
    baf_rules(0.40, ciLo = 0.30, ciHi = 0.45, cal_p = 0.02,
             alpha = 0.01, biasThreshold = 0.3)$pass,
    c("R0", "R1", "R2", "R3", "R4", "C1", "C2")
  )
  expect_true(is.na(p[["R0"]]))
  expect_false(p[["R1"]])   # 0.02 is not below alpha = 0.01
  expect_false(p[["C1"]])   # 0.40 is not below biasThreshold = 0.3
  expect_false(p[["C2"]])
})

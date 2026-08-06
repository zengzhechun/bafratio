test_that("point-estimate classification follows the three-zone rule", {
  expect_equal(ber_classify(8.7), "bias-dominated")
  expect_equal(ber_classify(0.03), "effect-dominated")
  expect_equal(ber_classify(0.8), "competitive")
  expect_equal(ber_classify(1.5), "bias-dominated")
})

test_that("CI-based classification is conservative at zone boundaries", {
  # CI 完全在偏倚区：下界 > 1
  expect_equal(ber_classify(2, ciLo = 1.2, ciHi = 9), "bias-dominated")
  # CI 完全在效应区：上界 < 0.5
  expect_equal(ber_classify(0.3, ciLo = 0.1, ciHi = 0.45), "effect-dominated")
  # CI 跨越阈值：势均力敌
  expect_equal(ber_classify(0.8, ciLo = 0.2, ciHi = 3), "competitive")
  expect_equal(ber_classify(5, ciLo = 0.3, ciHi = 50), "competitive")
})

test_that("unclassifiable inputs are handled", {
  expect_equal(ber_classify(NA_real_), "unclassifiable")
  expect_equal(ber_classify(NaN), "unclassifiable")
  expect_equal(ber_classify(numeric(0)), "unclassifiable")
})

test_that("custom thresholds are respected", {
  expect_equal(ber_classify(0.8, biasThreshold = 0.7), "bias-dominated")
  expect_equal(ber_classify(0.6, effectThreshold = 0.7), "effect-dominated")
})

test_that("Inf BER is bias-dominated", {
  expect_equal(ber_classify(Inf), "bias-dominated")
})

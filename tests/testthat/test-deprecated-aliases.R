test_that("every deprecated name still exists, warns, and forwards correctly", {
  # 弃用别名层的完整性检查：0.4.0 把公开前缀统一到 baf_*，旧名必须继续可用
  # 且必须给出弃用提示。逐个点名，避免新增别名时忘记登记。
  deprecated <- list(
    ber_estimate    = "baf_estimate",
    ber_bootstrap   = "baf_bootstrap",
    ber_analyze     = "baf_analyze",
    ber_screen      = "baf_screen",
    ber_loo         = "baf_loo",
    ber_diagnostics = "baf_diagnostics",
    ber_pal         = "baf_pal",
    bf_screen       = "baf_screen",
    bf_classify     = "baf_classify",
    bf_rules        = "baf_rules",
    bf_fieller      = "baf_fieller",
    plot_bf_gauge   = "plot_baf_gauge",
    theme_biasratio = "theme_bafratio",
    bsr_estimate    = "baf_estimate",
    bsr_bootstrap   = "baf_bootstrap",
    bsr_classify    = "ber_classify",
    bsr_loo         = "baf_loo",
    bsr_diagnostics = "baf_diagnostics",
    bsr_analyze     = "baf_analyze"
  )
  ns <- asNamespace("bafratio")

  for (old in names(deprecated)) {
    expect_true(exists(old, envir = ns, inherits = FALSE), info = old)
    expect_true(is.function(get(old, envir = ns)), info = old)
  }

  # The replacement targets must all be exported and callable.
  for (new in unique(unlist(deprecated))) {
    expect_true(exists(new, envir = ns, inherits = FALSE), info = new)
  }
})

test_that("deprecated estimate aliases warn once and return identical values", {
  args <- list(sim_est$logRr, sim_est$seLogRr, sim_nc$logRr, sim_nc$seLogRr)
  ref <- do.call(baf_estimate, args)

  for (old in c("ber_estimate", "bsr_estimate")) {
    expect_warning(
      got <- do.call(get(old, envir = asNamespace("bafratio")), args),
      "deprecated"
    )
    expect_identical(got$baf, ref$baf)
    expect_identical(got$ber, ref$ber)
  }
})

test_that("deprecated classify aliases warn and agree with baf_classify", {
  expect_warning(got <- bf_classify(0.91, ciLo = 0.74, ciHi = 0.99), "deprecated")
  expect_identical(got, baf_classify(0.91, ciLo = 0.74, ciHi = 0.99))

  expect_warning(
    got2 <- bsr_classify(8.7),
    "deprecated"
  )
  expect_identical(got2, ber_classify(8.7))
})

test_that("ber_classify() is a sibling function, not a deprecated alias", {
  # 它按 BER 尺度接收输入，不是 baf_classify() 的旧名，因此不应发出弃用提示。
  expect_silent(ber_classify(8.7))
  expect_silent(ber_classify(0.03, ciLo = 0.01, ciHi = 0.1))
  # 两个分类器通过单调映射严格等价。
  b <- 0.45
  expect_identical(
    baf_classify(b, ciLo = 0.31, ciHi = 0.53),
    ber_classify(b / (1 - b), ciLo = 0.31 / (1 - 0.31), ciHi = 0.53 / (1 - 0.53))
  )
})

test_that("deprecated screen alias forwards its arguments", {
  expect_warning(
    sc <- ber_screen(sim_est$logRr, sim_est$seLogRr,
                     sim_nc$logRr, sim_nc$seLogRr, nBoot = 60, seed = 11),
    "deprecated"
  )
  ref <- baf_screen(sim_est$logRr, sim_est$seLogRr,
                    sim_nc$logRr, sim_nc$seLogRr, nBoot = 60, seed = 11)
  expect_identical(sc$layer2$baf, ref$layer2$baf)
  expect_identical(sc$verdict$code, ref$verdict$code)
})

test_that("demo datasets are well-formed", {
  expect_equal(nrow(sim_nc), 12)
  expect_named(sim_nc, c("outcome", "logRr", "seLogRr"))
  expect_true(all(sim_nc$seLogRr > 0))
  expect_equal(nrow(sim_est), 1)
  expect_equal(sim_est$logRr, -0.184)
  expect_equal(sim_est$seLogRr, 0.045)
})

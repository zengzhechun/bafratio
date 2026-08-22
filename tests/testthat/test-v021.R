# v0.2.1 regression tests: robust method (P1-4), classify kernel (P1-3),
# fieller convenience (P1-5), and seed safety (P1-2).

test_that("ber_estimate robust method matches eAppendix 13 Type I error at K=12", {
  # 复现论文 eAppendix 13 的参数化仿真：mu_B=-0.190, sigma_B=0.068，
  # 对照 SE 取论文给出的经验分布范围 0.025--0.302。稳健 p 用方差膨胀 + t(K-2)。
  skip_if_not_installed("EmpiricalCalibration")
  library(EmpiricalCalibration)
  muB <- -0.190
  sigmaB <- 0.068
  K <- 12
  B <- 2000

  # 固定对照 SE（代表论文的经验分布），与目标 SE 取自同一范围的下段
  set.seed(9)
  tau <- sort(runif(K, 0.025, 0.302))

  rej_plugin <- rej_robust <- 0L
  for (i in seq_len(B)) {
    g <- rnorm(K, muB, sqrt(tau^2 + sigmaB^2))
    nf <- fitNull(g, tau)
    mu_hat <- nf[1]
    sig_hat <- nf[2]
    tau_t <- runif(1, 0.025, 0.12)
    y <- rnorm(1, muB, sqrt(tau_t^2 + sigmaB^2))

    p_plugin <- calibrateP(nf, y, tau_t)
    Vmu <- 1 / sum(1 / (tau^2 + sig_hat^2))
    se_r <- sqrt(tau_t^2 + sig_hat^2 + Vmu)
    p_robust <- 2 * stats::pt(-abs((y - mu_hat) / se_r), df = K - 2)

    if (p_plugin < 0.05) rej_plugin <- rej_plugin + 1L
    if (p_robust < 0.05) rej_robust <- rej_robust + 1L
  }

  rate_plugin <- rej_plugin / B
  rate_robust <- rej_robust / B

  # 论文报告：plugin 11.4%、t(K-2) 6.6%（名义 5%）。
  # 断言稳健法 Type I error 落在 [5%, 8%]，且比 plugin 更不反保守。
  expect_true(rate_robust >= 0.05 && rate_robust <= 0.08,
              info = sprintf("robust Type I error %.3f outside [0.05, 0.08]", rate_robust))
  expect_lt(rate_robust, rate_plugin)
  expect_gt(rate_plugin, 0.05)  # plugin 应明显反保守
})

test_that("ber_estimate returns both p-values and defaults to plugin", {
  est <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
                      sim_nc$logRr, sim_nc$seLogRr)
  expect_true(is.finite(est$cal_p_robust) && est$cal_p_robust >= 0 && est$cal_p_robust <= 1)
  expect_equal(est$cal_p, est$cal_p_plugin, tolerance = 1e-12)
  expect_equal(est$cal_method, "plugin")
  expect_equal(est$cal_p, 0.6494, tolerance = 0.005)  # 历史锚点不变

  est_r <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
                        sim_nc$logRr, sim_nc$seLogRr, method = "robust")
  expect_equal(est_r$cal_method, "robust")
  expect_equal(est_r$cal_p, est_r$cal_p_robust, tolerance = 1e-12)
  expect_true(est_r$var_mu_bias > 0)
  # 该场景两种 p 都远大于 0.05，结论稳健；robust 通常略大（更保守/更诚实）
  expect_true(est_r$cal_p_robust >= est$cal_p_plugin - 1e-9)
})

test_that("bf_classify and ber_classify share one kernel (cross-scale equivalence)", {
  # 点估计模式：BF 与 BER 在各自分区内部（非边界）严格等价。
  # 边界值（bf=1/3、0.5）由单独的单测覆盖（两者均判 mixed）。
  for (bf in c(0.1, 0.2, 0.4, 0.55, 0.6, 0.8, 0.91, 0.99)) {
    expect_equal(bf_classify(bf), ber_classify(bf / (1 - bf)),
                 info = sprintf("bf=%.3f point mode", bf))
  }
  # 自定义阈值的点估计等价：bf_classify(b, t) == ber_classify(b/(1-b), t/(1-t))
  for (t in c(0.4, 0.6, 0.7)) {
    b <- 0.55
    expect_equal(bf_classify(b, biasThreshold = t),
                 ber_classify(b / (1 - b), biasThreshold = t / (1 - t)),
                 info = sprintf("threshold t=%.3f", t))
  }
  # CI 模式等价
  b <- 0.6
  cl <- 0.31
  ch <- 0.85
  expect_equal(
    bf_classify(b, ciLo = cl, ciHi = ch),
    ber_classify(b / (1 - b), ciLo = cl / (1 - cl), ciHi = ch / (1 - ch))
  )
  # 边界：BF = 1 映射到 BER = Inf，仍判偏倚主导
  expect_equal(bf_classify(1), "bias-dominated")
  expect_equal(bf_classify(1), ber_classify(Inf))
})

test_that("fieller convenience wraps a fitted object", {
  skip_if_not_installed("EmpiricalCalibration")
  fit <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
                     sim_nc$logRr, sim_nc$seLogRr, nBoot = 500, seed = 42)
  boot <- fit$bootstrap
  est <- fit$estimate

  manual <- bf_fieller(est$mu_bias, stats::var(boot$mu_draws, na.rm = TRUE),
                       est$log_rr_uncal, est$se_log_rr)
  from_ber <- bf_fieller(est, boot)
  from_full <- bf_fieller(fit, boot)
  from_alias <- fieller(fit, boot)

  expect_equal(from_ber, manual)
  expect_equal(from_full, manual)
  expect_equal(from_alias, manual)
  expect_true(from_ber$region %in% c("interior", "exterior", "empty", "whole"))
})

test_that("default seed = NULL gives non-reproducible resampling (no internal set.seed, P1-2)", {
  # 旧版 ber_analyze 硬编码 seed=42，会在内部调用 set.seed，使两次调用
  # 结果完全相同（即把用户的随机流重置到固定点，造成污染）。v0.2.1 默认
  # NULL，不调用 set.seed，两次调用接续的是不同的全局随机流，bootstrap
  # 重抽样结果应当不同——这正是"无污染"的行为证据。
  f1 <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
                    sim_nc$logRr, sim_nc$seLogRr, nBoot = 200)
  f2 <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
                    sim_nc$logRr, sim_nc$seLogRr, nBoot = 200)
  expect_false(identical(f1$bootstrap$boot_dist, f2$bootstrap$boot_dist),
               info = "default seed=NULL must not reseed; resampling should differ")
})

test_that("explicit seed is localized and reproducible (P1-2 + withr)", {
  set.seed(7)
  s0 <- .Random.seed
  f1 <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
                    sim_nc$logRr, sim_nc$seLogRr, nBoot = 300, seed = 42)
  # withr::with_seed 在调用结束后把全局 RNG 恢复到进入前的状态（s0）
  expect_identical(.Random.seed, s0)

  f2 <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
                    sim_nc$logRr, sim_nc$seLogRr, nBoot = 300, seed = 42)
  expect_equal(f1$bootstrap$ci_lo, f2$bootstrap$ci_lo)
  expect_equal(f1$bootstrap$boot_dist, f2$bootstrap$boot_dist)
})

test_that("ber_bootstrap reuses the point estimate without re-fitting (P1-1)", {
  est <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
                      sim_nc$logRr, sim_nc$seLogRr)
  b <- ber_bootstrap(sim_est$logRr, sim_est$seLogRr,
                     sim_nc$logRr, sim_nc$seLogRr, nBoot = 300, seed = 42)
  expect_equal(b$ber, est$ber, tolerance = 1e-12)
})

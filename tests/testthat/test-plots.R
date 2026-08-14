test_that("all plot functions return ggplot objects that build without error", {
  fit <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
                     sim_nc$logRr, sim_nc$seLogRr,
                     ncNames = sim_nc$outcome,
                     nBoot = 300, seed = 42, loo = TRUE, looBoot = 50)

  plots <- list(
    plot_gauge(fit),
    plot_gauge(fit$estimate),   # 无 CI 版本
    plot_null(fit),
    plot_calibration(fit),
    plot_qq(fit),
    plot_loo(fit),
    plot_boot(fit)
  )
  for (p in plots) {
    expect_s3_class(p, "gg")
    expect_no_error(ggplot2::ggplot_build(p))
  }
})

test_that("plot_null labels outliers only when many NCs", {
  skip_if_not_installed("EmpiricalCalibration")
  data(sccs, package = "EmpiricalCalibration")
  nc <- sccs[sccs$groundTruth == 0, ]
  pc <- sccs[sccs$groundTruth == 1, ]
  est <- ber_estimate(pc$logRr, pc$seLogRr, nc$logRr, nc$seLogRr,
                      ncNames = nc$drugName)
  p <- plot_null(est)
  expect_no_error(ggplot2::ggplot_build(p))
  # 45 个 NC 时默认只标 |z| > 1.5 的离群点：标签层数据行数应少于 45。
  # 不硬编码层序号（图层顺序调整即失效）：含 label 列的层有两个
  # （NC 标签层 + "Primary estimate" 单行注释层），取多行的那个
  layerData <- ggplot2::ggplot_build(p)$data
  labelLayer <- Filter(function(d) "label" %in% names(d) && nrow(d) > 1,
                       layerData)
  expect_equal(length(labelLayer), 1)
  expect_lt(nrow(labelLayer[[1]]), 45)
})

test_that("plot functions reject wrong input classes with clear errors", {
  expect_error(plot_qq(42), "ber_diag")
  expect_error(plot_loo(42), "ber_loo")
  expect_error(plot_boot(42), "ber_boot")
  expect_error(plot_gauge(42), "ber")
})

test_that("S3 plot methods dispatch and print", {
  fit <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
                     sim_nc$logRr, sim_nc$seLogRr,
                     ncNames = sim_nc$outcome,
                     nBoot = 300, seed = 42, loo = TRUE, looBoot = 50)
  expect_no_error(plot(fit))
  expect_no_error(plot(fit$estimate))
  expect_no_error(plot(fit$bootstrap))
  expect_no_error(plot(fit$diagnostics))
  expect_no_error(plot(fit$loo))
})

test_that("ber_pal exposes the three-zone colors and theme builds", {
  pal <- ber_pal()
  expect_named(pal, c("bias-dominated", "mixed", "effect-dominated"))
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", pal)))
  expect_s3_class(theme_biasratio(), "theme")
})

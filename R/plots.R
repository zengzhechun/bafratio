# Visualization functions
# 设计原则：直接标注（direct labeling）优先于图例；分区既用颜色也用位置与文字
# 三重编码，保证色盲读者与黑白打印均可读；所有比值轴统一 log 尺度。

#' BER gauge: point estimate and CI on the three-zone scale
#'
#' The signature plot of the package. Shows the BER (and its bootstrap CI,
#' when available) on a log-scaled number line divided into the three
#' credibility zones.
#'
#' @param x An object of class `biasratio` (uses its bootstrap CI) or `ber`
#'   (point estimate only).
#' @param digits Rounding for annotations.
#'
#' @return A `ggplot` object.
#' @export
#' @examples
#' fit <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
#'                    sim_nc$logRr, sim_nc$seLogRr, nBoot = 500, seed = 42)
#' plot_gauge(fit)
plot_gauge <- function(x, digits = 2) {
  est <- asBerObject(x)
  hasCi <- inherits(x, "biasratio")
  ciLo <- if (hasCi) x$bootstrap$ci_lo else NA_real_
  ciHi <- if (hasCi) x$bootstrap$ci_hi else NA_real_
  cls <- if (hasCi) x$classification else est$classification
  ber <- est$ber
  clsCol <- classColor(cls)
  pal <- ber_pal()

  # 窗口始终完整覆盖三个分区的边界与全部数据点
  lo <- min(0.08, ber / 2, if (hasCi) ciLo / 2 else Inf)
  hi <- max(4, ber * 2, if (hasCi) ciHi * 1.6 else 0)

  zoneDf <- data.frame(
    xmin = c(lo, 0.5, 1),
    xmax = c(0.5, 1, hi),
    zone = c("effect-dominated", "competitive", "bias-dominated"),
    # 分区标签放在各自 log 区间的几何中心
    xmid = 10^((log10(c(lo, 0.5, 1)) + log10(c(0.5, 1, hi))) / 2)
  )
  # 为什么分层摆放标签：效应主导案例中 competitive/bias 两个区在 log 轴上
  # 很窄，同一高度会相互碰撞；窄区标签上移一层错开
  zoneDf$ylab <- c(0.45, 0.45, 0.45)
  logWidths <- diff(log10(c(lo, 0.5, 1, hi)))
  if (logWidths[2] < 0.7 || logWidths[3] < 0.7) {
    zoneDf$ylab[2] <- 0.60
    if (logWidths[3] < 0.7) zoneDf$ylab[3] <- 0.45
  }

  subtitle <- if (hasCi) {
    sprintf("BER = %s,  %d%% CI [%s, %s]  ->  %s",
            fmtNum(ber, digits), round(x$bootstrap$level * 100),
            fmtNum(ciLo, digits), fmtNum(ciHi, digits), cls)
  } else {
    sprintf("BER = %s  ->  %s (point estimate; run ber_bootstrap for a CI)",
            fmtNum(ber, digits), cls)
  }

  p <- ggplot2::ggplot() +
    ggplot2::annotate("rect",
                      xmin = zoneDf$xmin, xmax = zoneDf$xmax,
                      ymin = -0.32, ymax = 0.32,
                      fill = pal[zoneDf$zone], alpha = 0.13) +
    ggplot2::annotate("text",
                      x = zoneDf$xmid, y = zoneDf$ylab, label = zoneDf$zone,
                      color = pal[zoneDf$zone], fontface = "bold",
                      size = 3.4) +
    ggplot2::annotate("segment",
                      x = c(0.5, 1), xend = c(0.5, 1),
                      y = -0.32, yend = 0.32,
                      linetype = "dashed", color = "grey55") +
    ggplot2::annotate("text", x = ber, y = -0.5,
                      label = paste0("BER = ", fmtNum(ber, digits)),
                      color = clsCol, fontface = "bold", size = 4.2) +
    ggplot2::geom_point(ggplot2::aes(x = ber, y = 0),
                        color = clsCol, size = 5.5) +
    ggplot2::scale_x_log10(
      breaks = c(0.01, 0.1, 0.5, 1, 2, 10, 100),
      labels = function(z) sprintf("%g", z),
      limits = c(lo, hi)
    ) +
    ggplot2::coord_cartesian(ylim = c(-0.66, 0.74)) +
    ggplot2::labs(
      title = "Bias-effect ratio gauge",
      subtitle = subtitle,
      x = "BER (log scale)", y = NULL,
      caption = "Zones: BER < 0.5 effect-dominated | 0.5-1 competitive | > 1 bias-dominated"
    ) +
    theme_biasratio() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.title.y = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank()
    )

  if (hasCi) {
    # annotate("errorbarh") 内部走已弃用的 GeomErrorbarh；
    # 用 geom = "errorbar" + orientation = "y"（翻转后帽宽参数为 width）
    p <- p + ggplot2::annotate("errorbar",
                               xmin = ciLo, xmax = ciHi, y = 0,
                               orientation = "y",
                               width = 0.15, linewidth = 1.1, color = clsCol)
  }
  p
}

#' Empirical null "fingerprint" of the negative controls
#'
#' Scatter of negative control estimates against their standard errors, with
#' the fitted empirical null shown as a 95% band
#' \eqn{\mu_B \pm 1.96 \sqrt{se^2 + \sigma_B^2}}. The primary estimate is
#' overlaid as a diamond: a diamond lying inside the cloud of negative
#' controls is the visual signature of a bias-dominated association.
#'
#' @param x An object of class `ber` or `biasratio`.
#' @param labelAll Logical. Label every negative control (`TRUE`) or only
#'   potential outliers with |standardized residual| > 1.5 (`FALSE`,
#'   default when more than 20 controls).
#'
#' @return A `ggplot` object.
#' @export
#' @examples
#' fit <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
#'                     sim_nc$logRr, sim_nc$seLogRr, ncNames = sim_nc$outcome)
#' plot_null(fit)
plot_null <- function(x, labelAll = NULL) {
  est <- asBerObject(x)
  mu <- est$mu_bias
  sigma <- est$sigma_bias
  ncDf <- data.frame(
    se = est$nc_se_log_rr,
    est = est$nc_log_rr,
    name = est$nc_names
  )
  # 默认标注策略：NC 数量少时全标；数量多时只标疑似离群点，避免标签重叠
  if (is.null(labelAll)) labelAll <- nrow(ncDf) <= 20
  stdResid <- (ncDf$est - mu) / sqrt(ncDf$se^2 + sigma^2)
  labDf <- if (labelAll) ncDf else ncDf[abs(stdResid) > 1.5, ]

  seGrid <- seq(0, max(ncDf$se, est$se_log_rr) * 1.08, length.out = 120)
  bandDf <- data.frame(
    se = seGrid,
    ymin = mu - 1.96 * sqrt(seGrid^2 + sigma^2),
    ymax = mu + 1.96 * sqrt(seGrid^2 + sigma^2)
  )
  biasCol <- ber_pal()[["bias-dominated"]]

  ggplot2::ggplot() +
    ggplot2::geom_ribbon(
      data = bandDf,
      ggplot2::aes(x = .data$se, ymin = .data$ymin, ymax = .data$ymax),
      fill = biasCol, alpha = 0.14
    ) +
    ggplot2::geom_hline(yintercept = 0, color = "grey60", linewidth = 0.4) +
    ggplot2::geom_hline(yintercept = mu, linetype = "dashed",
                        color = biasCol, linewidth = 0.7) +
    ggplot2::geom_errorbar(
      data = ncDf,
      ggplot2::aes(x = .data$se,
                   ymin = .data$est - 1.96 * .data$se,
                   ymax = .data$est + 1.96 * .data$se),
      width = 0, alpha = 0.4, color = "grey40"
    ) +
    ggplot2::geom_point(
      data = ncDf,
      ggplot2::aes(x = .data$se, y = .data$est),
      size = 2.6, color = "#1B2A41"
    ) +
    ggplot2::geom_text(
      data = labDf,
      ggplot2::aes(x = .data$se, y = .data$est, label = .data$name),
      nudge_y = 0.055 * diff(range(c(ncDf$est, bandDf$ymin, bandDf$ymax))),
      size = 2.9, color = "grey30", check_overlap = TRUE
    ) +
    ggplot2::annotate("point", x = est$se_log_rr, y = est$log_rr_uncal,
                      shape = 18, size = 5, color = biasCol) +
    ggplot2::annotate("text", x = est$se_log_rr, y = est$log_rr_uncal,
                      label = "Primary estimate", color = biasCol,
                      fontface = "bold", size = 3.4, vjust = -1.1) +
    ggplot2::labs(
      title = "Empirical null distribution (negative control fingerprint)",
      subtitle = sprintf("mu_B = %s, sigma_B = %s; dashed line = bias center; band = 95%% region",
                         fmtNum(mu, 3), fmtNum(sigma, 3)),
      x = "Standard error of log RR",
      y = "Log relative risk"
    ) +
    theme_biasratio()
}

#' Effect estimate before vs after empirical calibration
#'
#' A clinician-facing comparison: the uncalibrated and calibrated relative
#' risks with their confidence intervals. The calibrated CI is wider because
#' it incorporates the systematic error variance.
#'
#' @param x An object of class `ber` or `biasratio`.
#' @param level Confidence level for the displayed intervals.
#'
#' @return A `ggplot` object.
#' @export
#' @examples
#' fit <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
#'                     sim_nc$logRr, sim_nc$seLogRr)
#' plot_calibration(fit)
plot_calibration <- function(x, level = 0.95) {
  est <- asBerObject(x)
  z <- stats::qnorm(1 - (1 - level) / 2)
  cls <- if (inherits(x, "biasratio")) x$classification else est$classification

  what <- factor(
    c(
      sprintf("Uncalibrated\np %s", fmtP(est$p_uncal)),
      sprintf("Calibrated\ncalibrated p %s", fmtP(est$cal_p))
    ),
    levels = c(
      sprintf("Calibrated\ncalibrated p %s", fmtP(est$cal_p)),
      sprintf("Uncalibrated\np %s", fmtP(est$p_uncal))
    )
  )
  plotDf <- data.frame(
    what = what,
    rr = c(est$rr_uncal, est$rr_cal),
    lo = exp(c(est$log_rr_uncal - z * est$se_log_rr,
               est$log_rr_cal - z * est$se_log_rr_cal)),
    hi = exp(c(est$log_rr_uncal + z * est$se_log_rr,
               est$log_rr_cal + z * est$se_log_rr_cal))
  )
  # 颜色按水平名显式映射：levels 顺序是 (Calibrated, Uncalibrated)，
  # Calibrated 用落区颜色（视觉主角），Uncalibrated 用中性灰（对照组）
  cols <- stats::setNames(c(classColor(cls), "grey45"), levels(what))

  ggplot2::ggplot(plotDf, ggplot2::aes(y = .data$what)) +
    ggplot2::geom_vline(xintercept = 1, linetype = "dashed", color = "grey55") +
    # geom_errorbarh 在 ggplot2 4.0 弃用：改用 orientation = "y"，
    # 此时端帽尺寸参数名是 width 而非 height（传 height 会触发转换警告）
    ggplot2::geom_errorbar(ggplot2::aes(xmin = .data$lo, xmax = .data$hi,
                                        color = .data$what),
                           orientation = "y", width = 0.16, linewidth = 1.1) +
    ggplot2::geom_point(ggplot2::aes(x = .data$rr, color = .data$what),
                        size = 4.5) +
    ggplot2::geom_text(ggplot2::aes(x = .data$rr, label = sprintf("RR = %.2f", .data$rr),
                                    color = .data$what),
                       vjust = -0.9, size = 3.6, fontface = "bold",
                       show.legend = FALSE) +
    ggplot2::scale_color_manual(values = cols, guide = "none") +
    ggplot2::scale_x_log10(labels = function(v) sprintf("%g", v)) +
    # 为什么用 expansion 而非 coord_cartesian(ylim)：y 轴是离散刻度，
    # 数值型 ylim 会强制转成连续刻度而报错；扩展量用加法空间更稳
    ggplot2::scale_y_discrete(expand = ggplot2::expansion(add = c(0.6, 1.0))) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(
      title = "Effect estimate before vs after empirical calibration",
      subtitle = sprintf("BER = %s -> %s; calibrated CI incorporates systematic error (sigma_B = %s)",
                         fmtNum(est$ber, 2), cls, fmtNum(est$sigma_bias, 3)),
      x = "Relative risk (log scale)", y = NULL,
      caption = "Dashed line: no effect (RR = 1)"
    ) +
    theme_biasratio()
}

#' Q-Q plot of standardized negative control residuals
#'
#' @param x An object of class `ber_diag` or `biasratio`.
#'
#' @return A `ggplot` object.
#' @export
#' @examples
#' d <- ber_diagnostics(sim_nc$logRr, sim_nc$seLogRr, ncNames = sim_nc$outcome)
#' plot_qq(d)
plot_qq <- function(x) {
  diagObj <- if (inherits(x, "biasratio")) x$diagnostics else x
  if (!inherits(diagObj, "ber_diag")) {
    stop("`x` must be an object of class `ber_diag` or `biasratio`.", call. = FALSE)
  }
  qqDf <- diagObj$qq
  # 按标准化残差找回名字用于离群点标注
  ord <- order(diagObj$std_residuals)
  qqDf$name <- diagObj$nc_names[ord]
  outDf <- qqDf[abs(qqDf$sample) > 2, ]

  p <- ggplot2::ggplot(qqDf, ggplot2::aes(x = .data$theoretical, y = .data$sample)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = "dashed",
                         color = "grey55") +
    ggplot2::geom_point(size = 2.6, color = "#1B2A41") +
    ggplot2::labs(
      title = "Q-Q plot of standardized negative control residuals",
      subtitle = sprintf("Shapiro-Wilk p = %s; residuals standardized by marginal SD sqrt(se^2 + sigma_B^2)",
                         fmtP(diagObj$shapiro_p)),
      x = "Theoretical normal quantiles",
      y = "Sample quantiles"
    ) +
    theme_biasratio()
  if (nrow(outDf) > 0) {
    p <- p + ggplot2::geom_text(
      data = outDf,
      ggplot2::aes(label = .data$name),
      nudge_y = 0.12, size = 3, color = ber_pal()[["bias-dominated"]],
      check_overlap = TRUE
    )
  }
  p
}

#' Forest plot of leave-one-out BER sensitivity
#'
#' @param x An object of class `ber_loo`, or a `biasratio` object created
#'   with `loo = TRUE`.
#'
#' @return A `ggplot` object.
#' @export
#' @examples
#' loo <- ber_loo(sim_est$logRr, sim_est$seLogRr,
#'                sim_nc$logRr, sim_nc$seLogRr,
#'                ncNames = sim_nc$outcome, nBoot = 100, seed = 1)
#' plot_loo(loo)
plot_loo <- function(x) {
  looDf <- if (inherits(x, "biasratio")) x$loo else x
  if (is.null(looDf) || !inherits(looDf, "ber_loo")) {
    stop("`x` must be a `ber_loo` data frame or a `biasratio` object with `loo = TRUE`.",
         call. = FALSE)
  }
  looDf$excluded <- stats::reorder(looDf$excluded, looDf$ber)
  hasCi <- any(!is.na(looDf$ci_lo))
  pal <- ber_pal()

  p <- ggplot2::ggplot(looDf, ggplot2::aes(y = .data$excluded, x = .data$ber)) +
    ggplot2::geom_vline(xintercept = 1, linetype = "dashed", color = "grey55") +
    ggplot2::geom_point(ggplot2::aes(color = .data$classification), size = 3.2) +
    ggplot2::scale_color_manual(values = pal, name = NULL) +
    ggplot2::scale_x_log10(labels = function(v) sprintf("%g", v)) +
    ggplot2::labs(
      title = "Leave-one-out sensitivity of the BER",
      subtitle = "Each row excludes one negative control and refits the empirical null",
      x = "BER after exclusion (log scale)",
      y = "Excluded negative control",
      caption = "Dashed line: BER = 1 (bias equals calibrated signal)"
    ) +
    theme_biasratio()
  if (hasCi) {
    p <- p + ggplot2::geom_errorbar(
      ggplot2::aes(xmin = .data$ci_lo, xmax = .data$ci_hi,
                   color = .data$classification),
      orientation = "y", width = 0.2, linewidth = 0.8
    )
  }
  p
}

#' Bootstrap distribution of the BER
#'
#' @param x An object of class `ber_boot` or `biasratio`.
#' @param bins Number of histogram bins.
#'
#' @return A `ggplot` object.
#' @export
#' @examples
#' boot <- ber_bootstrap(sim_est$logRr, sim_est$seLogRr,
#'                       sim_nc$logRr, sim_nc$seLogRr, nBoot = 500, seed = 42)
#' plot_boot(boot)
plot_boot <- function(x, bins = 40) {
  boot <- if (inherits(x, "biasratio")) x$bootstrap else x
  if (!inherits(boot, "ber_boot")) {
    stop("`x` must be an object of class `ber_boot` or `biasratio`.", call. = FALSE)
  }
  valid <- boot$boot_dist[!is.na(boot$boot_dist)]
  histDf <- data.frame(logBer = log10(valid))
  clsCol <- classColor(ber_classify(boot$ber, boot$ci_lo, boot$ci_hi))

  ggplot2::ggplot(histDf, ggplot2::aes(x = .data$logBer)) +
    ggplot2::annotate("rect",
                      xmin = log10(boot$ci_lo), xmax = log10(boot$ci_hi),
                      ymin = -Inf, ymax = Inf,
                      fill = clsCol, alpha = 0.10) +
    ggplot2::geom_histogram(bins = bins, fill = "#1B2A41", alpha = 0.75,
                            color = "white", linewidth = 0.2) +
    ggplot2::geom_vline(xintercept = log10(boot$ber), color = clsCol,
                        linewidth = 1.1) +
    ggplot2::scale_x_continuous(
      labels = function(z) sprintf("%g", 10^z)
    ) +
    ggplot2::labs(
      title = "Bootstrap distribution of the BER",
      subtitle = sprintf("%d successful replicates; shaded band = %d%% CI [%s, %s]; line = point estimate",
                         length(valid), round(boot$level * 100),
                         fmtNum(boot$ci_lo, 2), fmtNum(boot$ci_hi, 2)),
      x = "BER (log10 axis, labels on ratio scale)",
      y = "Count"
    ) +
    theme_biasratio()
}

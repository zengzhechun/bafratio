# S3 methods: print / summary / plot
# 设计原则：print 面向临床读者——先说结论（落区），再给关键数字，技术细节靠后。

#' @export
print.ber <- function(x, ...) {
  cat("Bias-effect ratio (BER) analysis\n")
  cat(strrep("=", 48), "\n", sep = "")
  cat(sprintf("Empirical null:  mu_B = %s, sigma_B = %s  (K = %d negative controls)\n",
              fmtNum(x$mu_bias, 3), fmtNum(x$sigma_bias, 3), length(x$nc_log_rr)))
  cat(sprintf("Uncalibrated:    RR = %s,  p %s\n",
              fmtNum(x$rr_uncal, 3), fmtP(x$p_uncal)))
  cat(sprintf("Calibrated:      RR = %s,  calibrated p %s\n",
              fmtNum(x$rr_cal, 3), fmtP(x$cal_p)))
  cat(sprintf("BAF  = %s  (share of calibrated signal that is bias)\n",
              fmtNum(x$bf, 3)))
  cat(sprintf("BER = %s  ->  %s\n",
              fmtNum(x$ber, 2), x$classification))
  cat(strrep("-", 48), "\n", sep = "")
  cat("Point-estimate classification; for CI-based classification\n")
  cat("see ber_bootstrap() / ber_analyze().\n")
  invisible(x)
}

#' @export
print.ber_boot <- function(x, ...) {
  cat("Bootstrap CI for the bias-effect ratio\n")
  cat(strrep("=", 48), "\n", sep = "")
  cat(sprintf("BAF  = %s,  %d%% CI [%s, %s]  (bootstrap median)\n",
              fmtNum(x$bf_median, 3), round(x$level * 100),
              fmtNum(x$bf_ci_lo, 3), fmtNum(x$bf_ci_hi, 3)))
  cat(sprintf("BER = %s,  %d%% CI [%s, %s]  (method = %s)\n",
              fmtNum(x$ber, 2), round(x$level * 100),
              fmtNum(x$ci_lo, 2), fmtNum(x$ci_hi, 2), x$method))
  cat(sprintf("Replicates: %d, fitNull failures: %d (success rate %.1f%%)\n",
              x$n_boot, x$n_fail, 100 * x$success_rate))
  cat(sprintf("Classification: %s\n",
              ber_classify(x$ber, x$ci_lo, x$ci_hi)))
  invisible(x)
}

#' @export
print.ber_diag <- function(x, ...) {
  cat("Empirical null diagnostics\n")
  cat(strrep("=", 48), "\n", sep = "")
  cat(sprintf("mu_B = %s, sigma_B = %s\n", fmtNum(x$mu, 4), fmtNum(x$sigma, 4)))
  cat(sprintf("Shapiro-Wilk normality p = %s\n", fmtP(x$shapiro_p)))
  cat(sprintf("Largest |standardized residual|: %s (%s)\n",
              fmtNum(x$max_resid, 2), x$max_resid_name))
  cat("Note: residuals are standardized by the marginal SD\n")
  cat("sqrt(se^2 + sigma_B^2), not by se alone.\n")
  invisible(x)
}

#' @export
print.biasratio <- function(x, ...) {
  est <- x$estimate
  boot <- x$bootstrap
  cat("biasratio: full BER analysis\n")
  cat(strrep("=", 56), "\n", sep = "")
  cat(sprintf("Empirical null:  mu_B = %s, sigma_B = %s  (K = %d negative controls)\n",
              fmtNum(est$mu_bias, 3), fmtNum(est$sigma_bias, 3),
              length(est$nc_log_rr)))
  cat(sprintf("BAF  = %s  |  BER = %s\n",
              fmtNum(boot$bf_median, 3), fmtNum(boot$ber_median, 2)))
  cat(sprintf("Uncalibrated:    RR = %s [%.3f, %.3f],  p %s\n",
              fmtNum(est$rr_uncal, 3),
              exp(est$log_rr_uncal - 1.96 * est$se_log_rr),
              exp(est$log_rr_uncal + 1.96 * est$se_log_rr),
              fmtP(est$p_uncal)))
  cat(sprintf("Calibrated:      RR = %s,  calibrated p %s\n",
              fmtNum(est$rr_cal, 3), fmtP(est$cal_p)))
  cat(sprintf("BER = %s,  %d%% CI [%s, %s]  (%s bootstrap, n = %d)\n",
              fmtNum(est$ber, 2), round(boot$level * 100),
              fmtNum(boot$ci_lo, 2), fmtNum(boot$ci_hi, 2),
              boot$method, boot$n_boot))
  cat(sprintf("Classification (CI-based):  %s\n", x$classification))
  cat(sprintf("Diagnostics: Shapiro-Wilk p = %s; max |std. resid| = %s (%s)\n",
              fmtP(x$diagnostics$shapiro_p),
              fmtNum(x$diagnostics$max_resid, 2),
              x$diagnostics$max_resid_name))
  if (!is.null(x$loo)) {
    nBd <- sum(x$loo$classification == "bias-dominated")
    cat(sprintf("Leave-one-out: %d/%d exclusions remain bias-dominated\n",
                nBd, nrow(x$loo)))
  }
  invisible(x)
}

#' @export
summary.biasratio <- function(object, ...) {
  print(object, ...)
  invisible(object)
}

#' @export
plot.ber <- function(x, ...) {
  print(plot_calibration(x, ...))
  invisible(x)
}

#' @export
plot.ber_boot <- function(x, ...) {
  print(plot_boot(x, ...))
  invisible(x)
}

#' @export
plot.ber_diag <- function(x, ...) {
  print(plot_qq(x, ...))
  invisible(x)
}

#' @export
plot.ber_loo <- function(x, ...) {
  print(plot_loo(x, ...))
  invisible(x)
}

#' @export
plot.biasratio <- function(x, ...) {
  # P2-8: 默认出有界的 BAF gauge 而非 BER gauge。论文以 BAF 为第一语言，
  # 且 BAF 天然落在 [0,1]，不存在 BER 那种 log 窗口自适应挤压分区的问题；
  # BER gauge 仍保留给偏好比值语言的读者（plot_gauge）。
  print(plot_bf_gauge(x, ...))
  invisible(x)
}

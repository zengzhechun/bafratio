#' Bootstrap confidence interval for the bias-effect ratio
#'
#' Resamples the negative controls with replacement, refits the empirical
#' null for each replicate, and recomputes the BER. The confidence interval
#' is computed on the log scale and exponentiated back.
#'
#' @details
#' The BER is a strictly positive, right-skewed ratio estimator. Computing
#' the percentile interval on the log scale yields a roughly symmetric
#' bootstrap distribution and confidence limits with correct
#' order-of-magnitude coverage — standard practice for ratio-type estimators
#' such as risk ratios. The raw percentile interval is available as an
#' alternative via `method = "percentile"`.
#'
#' Bootstrap replicates for which [EmpiricalCalibration::fitNull()] fails to
#' converge are recorded as `NA` and excluded from the interval; a warning is
#' raised when the success rate drops below 50%.
#'
#' @inheritParams ber_estimate
#' @param nBoot Number of bootstrap replicates (default 2000).
#' @param seed Optional random seed for reproducibility. Defaults to `NULL`,
#'   in which case the caller's RNG is left untouched; when supplied, the
#'   seed is localized with [withr::with_seed()] and does **not** pollute the
#'   global RNG stream.
#' @param level Confidence level (default 0.95).
#' @param method `"log"` (default; percentile interval on the log scale, then
#'   exponentiated) or `"percentile"` (raw percentile interval).
#'
#' @return An object of class `ber_boot`: a list with components
#'   \describe{
#'     \item{ci_lo, ci_hi}{Confidence limits for the BER.}
#'     \item{bf_ci_lo, bf_ci_hi}{Confidence limits for the BAF, obtained as
#'       the monotone transform of the log-scale BER interval (equivalently,
#'       a percentile interval on the logit scale).}
#'     \item{level, method}{As supplied.}
#'     \item{ber}{Raw-ratio point estimate of the BER (from
#'       [ber_estimate()]).}
#'     \item{ber_median, bf_median}{Bootstrap-median point estimates
#'       (median on the log scale, back-transformed). These are the primary
#'       reported point estimates: they come from the same distribution as
#'       the CI, so they cannot fall outside it.}
#'     \item{boot_dist, boot_bf_dist}{Numeric vectors of length `nBoot`
#'       with the bootstrap BER and BAF replicates (`NA` for failed
#'       iterations).}
#'     \item{n_fail, n_boot, success_rate}{Convergence diagnostics.}
#'   }
#'
#' @export
#' @examples
#' # 演示用较少重抽样；正式分析建议 nBoot >= 2000
#' boot <- ber_bootstrap(sim_est$logRr, sim_est$seLogRr,
#'                       sim_nc$logRr, sim_nc$seLogRr,
#'                       nBoot = 500, seed = 42)
#' boot
ber_bootstrap <- function(logRr, seLogRr, ncLogRr, ncSeLogRr,
                          nBoot = 2000, seed = NULL, level = 0.95,
                          method = c("log", "percentile")) {
  method <- match.arg(method)
  checkEstimateInputs(logRr, seLogRr, ncLogRr, ncSeLogRr)

  # P1-1: 主 fitNull 在循环外先算一次，循环后只复用其原始 BER。
  # 这样既不重复跑 MLE 优化器，也避免了循环内另一次 ber_estimate 失败时
  # （那次没有 tryCatch 兜底）使整个 bootstrap 崩溃的风险。
  est <- ber_estimate(logRr, seLogRr, ncLogRr, ncSeLogRr)

  run <- function() {
    K <- length(ncLogRr)
    bootBer <- rep(NA_real_, nBoot)
    bootMu <- rep(NA_real_, nBoot)
    logBer <- rep(NA_real_, nBoot)
    nFail <- 0L

    for (b in seq_len(nBoot)) {
      idx <- sample.int(K, K, replace = TRUE)
      nullFitB <- tryCatch(
        EmpiricalCalibration::fitNull(ncLogRr[idx], ncSeLogRr[idx]),
        error = function(e) NULL
      )
      # 为什么失败迭代记 NA 而不是静默替换或中止：重抽样下偶发 MLE 不收敛
      # 属正常现象；静默替换会污染分布，直接中止会浪费全部计算。
      # 诚实做法是记录失败率，过低时向用户告警。
      if (is.null(nullFitB)) {
        nFail <- nFail + 1L
        next
      }
      muB <- as.numeric(nullFitB[1])
      bootMu[b] <- muB
      logTrue <- logRr - muB
      # 防止校准后效应恰为 0 导致 BER 爆炸；1e-8 的数值地板不改变结论
      if (abs(logTrue) < 1e-8) logTrue <- if (logTrue >= 0) 1e-8 else -1e-8
      bootBer[b] <- abs(muB) / abs(logTrue)
      # 为什么加 1e-4 下限：muB 偶发恰为 0 时 log(0) = -Inf 会污染分位数
      logBer[b] <- log(max(bootBer[b], 1e-4))
    }

    valid <- bootBer[!is.na(bootBer)]
    if (length(valid) < nBoot * 0.5) {
      warning(sprintf(
        "Bootstrap success rate is low: %d/%d fitNull iterations failed.",
        nFail, nBoot
      ), call. = FALSE)
    }

    probs <- c((1 - level) / 2, 1 - (1 - level) / 2)
    ci <- if (method == "log") {
      exp(stats::quantile(logBer[!is.na(logBer)], probs, names = FALSE))
    } else {
      stats::quantile(valid, probs, names = FALSE)
    }

    # v0.2.0: bootstrap-median point estimates (median on the log scale,
    # back-transformed), so the point estimate and the CI come from the same
    # distribution. The raw ratio can fall outside its own bootstrap CI when
    # the calibrated effect sits near zero; the median cannot.
    berMedian <- exp(stats::median(logBer[!is.na(logBer)]))
    bfMedian <- berMedian / (1 + berMedian)
    bfCiLo <- ci[1] / (1 + ci[1])
    bfCiHi <- ci[2] / (1 + ci[2])

    structure(
      list(
        ci_lo = unname(ci[1]),
        ci_hi = unname(ci[2]),
        bf_ci_lo = unname(bfCiLo),
        bf_ci_hi = unname(bfCiHi),
        level = level,
        method = method,
        ber = est$ber,
        ber_median = unname(berMedian),
        bf_median = unname(bfMedian),
        boot_dist = bootBer,
        boot_bf_dist = bootBer / (1 + bootBer),
        mu_draws = bootMu,
        n_fail = nFail,
        n_boot = nBoot,
        success_rate = 1 - nFail / nBoot
      ),
      class = "ber_boot"
    )
  }

  # P1-2: 仅在用户显式传 seed 时局部化随机流，避免污染调用者的全局 RNG。
  if (!is.null(seed)) withr::with_seed(seed, run()) else run()
}

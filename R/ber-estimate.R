#' Estimate the bias fraction (BF) and the bias-effect ratio (BER)
#'
#' Fits an empirical null distribution to negative control (NC) effect
#' estimates, then expresses the estimated systematic bias relative to the
#' calibrated effect of interest. The bias fraction (BF) is the primary
#' bounded metric; the bias-effect ratio (BER) is retained as the auxiliary
#' unbounded display of the same information.
#'
#' @details
#' The empirical null \eqn{N(\mu_B, \sigma_B^2)} is estimated by maximum
#' likelihood from the NC estimates with [EmpiricalCalibration::fitNull()].
#' The calibrated log effect is \eqn{\log RR_{cal} = \log RR - \mu_B}, and
#'
#' \deqn{BF = \frac{|\mu_B|}{|\mu_B| + |\log RR_{cal}|}, \quad BF \in (0,1],
#' \qquad BER = \frac{|\mu_B|}{|\log RR_{cal}|} = \frac{BF}{1-BF}}
#'
#' BF is the share of the total calibrated signal (bias plus residual
#' effect) attributable to systematic bias. It is bounded, so BF = 1 when
#' the calibrated effect is exactly zero, and no special handling of
#' infinite values is needed at the null. The raw-ratio point estimate is
#' reported as `ber`; use [ber_bootstrap()] for the bootstrap-median point
#' estimates on both scales.
#'
#' Interpretation on the bounded scale (identical partition to the BER
#' thresholds 1 and 0.5):
#'
#' * **BF > 0.5** (BER > 1): systematic bias exceeds the calibrated signal
#'   (bias-dominated). The observed association can be entirely an artifact.
#' * **1/3 <= BF <= 0.5** (0.5 <= BER <= 1): bias and signal are of
#'   comparable magnitude (mixed).
#' * **BF < 1/3** (BER < 0.5): the calibrated signal clearly exceeds the
#'   estimated bias (effect-dominated).
#'
#' The calibrated standard error incorporates both random and systematic
#' error: \eqn{se_{cal} = \sqrt{se^2 + \sigma_B^2}} (Schuemie et al. 2018).
#'
#' @param logRr Numeric scalar. Log of the uncalibrated effect estimate
#'   (e.g. log relative risk) for the exposure-outcome pair of interest.
#' @param seLogRr Numeric scalar. Standard error of `logRr`.
#' @param ncLogRr Numeric vector. Log effect estimates for the negative
#'   control outcomes (or exposure controls); their true effects are assumed
#'   to be null.
#' @param ncSeLogRr Numeric vector. Standard errors of `ncLogRr`.
#' @param ncNames Optional character vector of labels for the negative
#'   controls, used in plots and diagnostics. Defaults to `names(ncLogRr)`,
#'   or `NC1 ... NCK` when no names are available.
#' @param method Calibrated p-value method. `"plugin"` (default) uses the
#'   Gaussian / null-normal calibrated p-value from
#'   [EmpiricalCalibration::calibrateP()] — the OHDSI convention and the
#'   historical default of this package. `"robust"` applies the small-sample
#'   correction from the companion paper's eAppendix 13: it inflates the
#'   plug-in variance by the estimation variance of the empirical-null mean,
#'   \eqn{\widehat{\mathrm{Var}}(\hat\mu_B)=[\sum_k(\hat\tau_k^2+\hat\sigma_B^2)^{-1}]^{-1}},
#'   and references a Student-t distribution with \eqn{K-2} degrees of
#'   freedom. Use `"robust"` (or report it as a sensitivity) when the number
#'   of negative controls is below ~20, where the plug-in p-value is
#'   materially anti-conservative.
#'
#' @return An object of class `ber`: a list with components
#'   \describe{
#'     \item{mu_bias, sigma_bias}{Mean and SD of the empirical null
#'       distribution (the estimated systematic bias).}
#'     \item{log_rr_uncal, se_log_rr}{Input effect estimate on the log scale.}
#'     \item{log_rr_cal, se_log_rr_cal}{Bias-calibrated log effect and its
#'       standard error \eqn{\sqrt{se^2 + \sigma_B^2}}.}
#'     \item{rr_uncal, rr_cal, rr_bias}{Ratio-scale quantities:
#'       uncalibrated RR, calibrated RR, and bias factor \eqn{e^{\mu_B}}.}
#'     \item{bf}{The bias fraction \eqn{|\mu_B| / (|\mu_B| + |\log RR_{cal}|)},
#'       in the unit interval; 1 when the calibrated effect is exactly 0 with non-zero
#'       bias, `NaN` when both are 0 (undefined).}
#'     \item{ber}{The auxiliary bias-effect ratio
#'       \eqn{|\mu_B| / |\log RR_{cal}|}; `Inf` when the calibrated effect
#'       is exactly 0 with non-zero bias, `NaN` when both are 0.}
#'     \item{p_uncal}{Nominal two-sided p-value from the Wald statistic.}
#'     \item{cal_p}{Two-sided calibrated p-value for the selected `method`
#'       (`"plugin"` or `"robust"`). Equals `cal_p_plugin` under the default.}
#'     \item{cal_p_plugin}{Plug-in (Gaussian / null-normal) calibrated p-value,
#'       from [EmpiricalCalibration::calibrateP()].}
#'     \item{cal_p_robust}{Small-sample robust calibrated p-value: variance
#'       inflation plus a t(K-2) reference distribution (eAppendix 13).}
#'     \item{cal_method}{The `method` used for `cal_p`.}
#'     \item{var_mu_bias}{Estimation variance of the empirical-null mean,
#'       \eqn{[\sum_k(\hat\tau_k^2+\hat\sigma_B^2)^{-1}]^{-1}}, used by the
#'       robust correction.}
#'     \item{classification}{Point-estimate-only classification; see
#'       [ber_classify()].}
#'     \item{nc_log_rr, nc_se_log_rr, nc_names}{The negative control data.}
#'     \item{null_fit}{The object returned by [EmpiricalCalibration::fitNull()].}
#'   }
#'
#' @references
#' Schuemie MJ, Ryan PB, DuMouchel W, Suchard MA, Madigan D. Interpreting
#' observational studies: why empirical calibration is needed to correct
#' p-values. *Statistics in Medicine* 2014; 33(2):209-218.
#'
#' Schuemie MJ, Hripcsak G, Ryan PB, Madigan D, Suchard MA. Empirical
#' confidence interval calibration for population-level effect estimation
#' studies in observational healthcare data. *PNAS* 2018; 115(11):2571-2577.
#'
#' @seealso [ber_bootstrap()] for confidence intervals, [ber_classify()] for
#'   the classification rule, [ber_analyze()] for the full workflow.
#'
#' @export
#' @examples
#' fit <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
#'                     sim_nc$logRr, sim_nc$seLogRr,
#'                     ncNames = sim_nc$outcome)
#' fit
ber_estimate <- function(logRr, seLogRr, ncLogRr, ncSeLogRr, ncNames = NULL,
                           method = c("plugin", "robust")) {
  method <- match.arg(method)
  checkEstimateInputs(logRr, seLogRr, ncLogRr, ncSeLogRr)
  ncNames <- resolveNcNames(ncNames, ncLogRr)

  nullFit <- EmpiricalCalibration::fitNull(ncLogRr, ncSeLogRr)
  muBias <- as.numeric(nullFit[1])
  sigmaBias <- as.numeric(nullFit[2])

  logRrCal <- logRr - muBias
  # 为什么校准后 SE 要并入 sigma_B：系统误差的随机涨落本身就是不确定性的
  # 一部分，只用抽样 SE 会高估精度（Schuemie 2018 的 calibrated CI 定义）
  seCal <- sqrt(seLogRr^2 + sigmaBias^2)

  # 校准 p 值：plugin 用 EmpiricalCalibration 的高斯参考；robust 用
  # eAppendix 13 的小样本校正（方差膨胀 + t(K-2) 参考分布）。
  calPplugin <- as.numeric(EmpiricalCalibration::calibrateP(nullFit, logRr, seLogRr))
  K <- length(ncLogRr)
  # 经验零均值 mu_B 的估计方差：各对照 inverse-variance 加和取逆。
  # 这一项正是 plugin 反保守的主要来源——它把 mu_B 当作已知而非估计。
  varMuBias <- 1 / sum(1 / (ncSeLogRr^2 + sigmaBias^2))
  seRobust <- sqrt(seLogRr^2 + sigmaBias^2 + varMuBias)
  zRobust <- (logRr - muBias) / seRobust
  calProbuf <- 2 * stats::pt(-abs(zRobust), df = K - 2)
  calP <- if (identical(method, "robust")) calProbuf else calPplugin

  # 边界：校准后效应恰为 0 时 BER 在数学上发散；偏倚也为 0 则无定义。
  # 显式返回 Inf/NaN 比静默加 epsilon 更诚实，下游 classify 能正确归类。
  if (abs(logRrCal) < 1e-10) {
    ber <- if (abs(muBias) < 1e-10) NaN else Inf
    bf <- if (abs(muBias) < 1e-10) NaN else 1
  } else {
    ber <- abs(muBias) / abs(logRrCal)
    bf <- ber / (1 + ber)
  }

  structure(
    list(
      mu_bias = muBias,
      sigma_bias = sigmaBias,
      log_rr_uncal = logRr,
      se_log_rr = seLogRr,
      log_rr_cal = logRrCal,
      se_log_rr_cal = seCal,
      rr_uncal = exp(logRr),
      rr_cal = exp(logRrCal),
      rr_bias = exp(muBias),
      bf = bf,
      ber = ber,
      p_uncal = 2 * stats::pnorm(-abs(logRr / seLogRr)),
      cal_p = calP,
      cal_p_plugin = calPplugin,
      cal_p_robust = calProbuf,
      cal_method = method,
      var_mu_bias = varMuBias,
      classification = ber_classify(ber),
      nc_log_rr = ncLogRr,
      nc_se_log_rr = ncSeLogRr,
      nc_names = ncNames,
      null_fit = nullFit
    ),
    class = "ber"
  )
}

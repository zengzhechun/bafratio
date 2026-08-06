#' Estimate the bias-effect ratio (BER)
#'
#' Fits an empirical null distribution to negative control (NC) effect
#' estimates, then expresses the estimated systematic bias relative to the
#' calibrated effect of interest.
#'
#' @details
#' The empirical null \eqn{N(\mu_B, \sigma_B^2)} is estimated by maximum
#' likelihood from the NC estimates with [EmpiricalCalibration::fitNull()].
#' The calibrated log effect is \eqn{\log RR_{cal} = \log RR - \mu_B}, and
#'
#' \deqn{BER = \frac{|\mu_B|}{|\log RR_{cal}|}}{BER = |mu_B| / |log RR_cal|}
#'
#' Interpretation on the ratio scale:
#'
#' * **BER > 1**: systematic bias exceeds the calibrated signal
#'   (bias-dominated). The observed association can be entirely an artifact.
#' * **0.5 < BER < 1**: bias and signal are of comparable magnitude
#'   (competitive).
#' * **BER < 0.5**: the calibrated signal clearly exceeds the estimated bias
#'   (effect-dominated).
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
#'     \item{ber}{The bias-effect ratio \eqn{|\mu_B| / |\log RR_{cal}|}.
#'       `Inf` when the calibrated effect is exactly 0 with non-zero bias;
#'       `NaN` when both are 0 (undefined).}
#'     \item{p_uncal}{Nominal two-sided p-value from the Wald statistic.}
#'     \item{cal_p}{Two-sided p-value calibrated against the empirical null,
#'       from [EmpiricalCalibration::calibrateP()].}
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
ber_estimate <- function(logRr, seLogRr, ncLogRr, ncSeLogRr, ncNames = NULL) {
  checkEstimateInputs(logRr, seLogRr, ncLogRr, ncSeLogRr)
  ncNames <- resolveNcNames(ncNames, ncLogRr)

  nullFit <- EmpiricalCalibration::fitNull(ncLogRr, ncSeLogRr)
  muBias <- as.numeric(nullFit[1])
  sigmaBias <- as.numeric(nullFit[2])

  logRrCal <- logRr - muBias
  # 为什么校准后 SE 要并入 sigma_B：系统误差的随机涨落本身就是不确定性的
  # 一部分，只用抽样 SE 会高估精度（Schuemie 2018 的 calibrated CI 定义）
  seCal <- sqrt(seLogRr^2 + sigmaBias^2)

  # 边界：校准后效应恰为 0 时 BER 在数学上发散；偏倚也为 0 则无定义。
  # 显式返回 Inf/NaN 比静默加 epsilon 更诚实，下游 classify 能正确归类。
  if (abs(logRrCal) < 1e-10) {
    ber <- if (abs(muBias) < 1e-10) NaN else Inf
  } else {
    ber <- abs(muBias) / abs(logRrCal)
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
      ber = ber,
      p_uncal = 2 * stats::pnorm(-abs(logRr / seLogRr)),
      cal_p = as.numeric(EmpiricalCalibration::calibrateP(nullFit, logRr, seLogRr)),
      classification = ber_classify(ber),
      nc_log_rr = ncLogRr,
      nc_se_log_rr = ncSeLogRr,
      nc_names = ncNames,
      null_fit = nullFit
    ),
    class = "ber"
  )
}

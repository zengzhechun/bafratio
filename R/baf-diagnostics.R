#' Diagnostics for the empirical null fit
#'
#' Assesses whether the negative control estimates are compatible with the
#' fitted empirical null distribution, using standardized residuals, a
#' Shapiro-Wilk normality test, and Q-Q data.
#'
#' @details
#' Under the empirical null, each NC estimate satisfies
#' \eqn{\hat\gamma_k \sim N(\mu_B, \tau_k^2 + \sigma_B^2)}, where
#' \eqn{\tau_k} is its sampling standard error. Standardized residuals are
#' therefore computed against the **marginal** SD
#' \eqn{\sqrt{\tau_k^2 + \sigma_B^2}}, not against \eqn{\tau_k} alone:
#' the systematic-error variance is part of the total variance.
#'
#' @inheritParams baf_estimate
#'
#' @return An object of class `baf_diag`: a list with components
#'   \describe{
#'     \item{mu, sigma}{Fitted empirical null parameters.}
#'     \item{residuals}{Raw residuals `ncLogRr - mu`.}
#'     \item{std_residuals}{Residuals standardized by the marginal SD.}
#'     \item{shapiro_p}{Shapiro-Wilk normality p-value for the standardized
#'       residuals (`NA` when the test is not applicable).}
#'     \item{max_resid_name, max_resid}{Label and value of the largest
#'       absolute standardized residual — the prime outlier candidate.}
#'     \item{qq}{Data frame with `theoretical` and `sample` quantiles for
#'       Q-Q plotting.}
#'     \item{nc_names}{Negative control labels.}
#'   }
#'
#' @export
#' @examples
#' diag <- baf_diagnostics(sim_nc$logRr, sim_nc$seLogRr,
#'                         ncNames = sim_nc$outcome)
#' diag
baf_diagnostics <- function(ncLogRr, ncSeLogRr, ncNames = NULL) {
  if (!is.numeric(ncLogRr) || !is.numeric(ncSeLogRr) ||
      length(ncLogRr) != length(ncSeLogRr) || length(ncLogRr) < 3L ||
      any(!is.finite(ncLogRr)) || any(!is.finite(ncSeLogRr)) ||
      any(ncSeLogRr <= 0)) {
    stop("`ncLogRr` and `ncSeLogRr` must be finite numeric vectors of equal length (>= 3), with positive standard errors.",
         call. = FALSE)
  }
  ncNames <- resolveNcNames(ncNames, ncLogRr)

  nullFit <- EmpiricalCalibration::fitNull(ncLogRr, ncSeLogRr)
  mu <- as.numeric(nullFit[1])
  sigma <- as.numeric(nullFit[2])

  residuals <- ncLogRr - mu
  # 为什么用边际 SD 标准化：经验零下 NC 的总变异 = 抽样方差 + 系统误差方差；
  # 只用 tau 会把系统性离散误判成离群
  marginalSd <- sqrt(ncSeLogRr^2 + sigma^2)
  stdResiduals <- residuals / marginalSd

  shapiroP <- tryCatch(
    stats::shapiro.test(stdResiduals)$p.value,
    error = function(e) NA_real_
  )
  maxIdx <- which.max(abs(stdResiduals))

  structure(
    list(
      mu = mu,
      sigma = sigma,
      residuals = residuals,
      std_residuals = stdResiduals,
      shapiro_p = shapiroP,
      max_resid_name = ncNames[maxIdx],
      max_resid = stdResiduals[maxIdx],
      qq = data.frame(
        theoretical = stats::qnorm(stats::ppoints(length(ncLogRr))),
        sample = sort(stdResiduals)
      ),
      nc_names = ncNames
    ),
    class = "baf_diag"
  )
}

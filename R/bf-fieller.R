#' Fieller confidence set for the ratio of bias to calibrated effect
#'
#' The signed ratio \eqn{\rho = \mu_B / \tilde\psi} underlies the BF through
#' \eqn{BF = |\rho| / (1 + |\rho|)}. Fieller's theorem gives the set of
#' \eqn{\rho} values consistent with the data at level \eqn{1-\alpha}, and
#' it degrades honestly when the calibrated effect is near zero: the set can
#' be an interior interval, the exterior of a finite interval, empty, or the
#' whole line.
#'
#' @details
#' With \eqn{m_1 = \hat\mu_B}, \eqn{m_2 = \tilde\psi = \log RR - \hat\mu_B},
#' \eqn{v_{11} = \mathrm{Var}(\hat\mu_B)}, \eqn{v_{22} = se^2 + v_{11}}, and
#' \eqn{v_{12} = -v_{11}} (the primary estimate is independent of the
#' negative controls), the set contains all \eqn{\rho} satisfying
#' \deqn{(m_1 - \rho m_2)^2 \le z^2_{\alpha/2}(v_{11} - 2\rho v_{12} + \rho^2 v_{22}).}
#'
#' @param muBias Numeric scalar. Estimated mean systematic bias (from
#'   [ber_estimate()], component `mu_bias`).
#' @param varMuBias Numeric scalar. Variance of `muBias`; typically estimated
#'   from the variance of the bootstrap resamples of the empirical null
#'   mean, or from the observed Fisher information.
#' @param logRr Numeric scalar. Log of the uncalibrated effect estimate.
#' @param seLogRr Numeric scalar. Standard error of `logRr`.
#' @param alpha Significance level (default 0.05 for a 95% set).
#'
#' @return A list with components `lo`, `hi` (bounds, `NA` when the region
#'   has no finite bounds) and `region`, one of `"interior"`
#'   (bounded interval), `"exterior"` (complement of a finite interval),
#'   `"empty"`, or `"whole"`.
#'
#' @references
#' Fieller EC. Some problems in interval estimation. *Journal of the Royal
#' Statistical Society: Series B* 1954; 16(2):175-185.
#'
#' @export
#' @examples
#' fit <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
#'                     sim_nc$logRr, sim_nc$seLogRr)
#' boot <- ber_bootstrap(sim_est$logRr, sim_est$seLogRr,
#'                       sim_nc$logRr, sim_nc$seLogRr, nBoot = 500, seed = 42)
#' bf_fieller(fit$mu_bias, var(boot$mu_draws, na.rm = TRUE),
#'            sim_est$logRr, sim_est$seLogRr)
bf_fieller <- function(muBias, varMuBias, logRr, seLogRr, alpha = 0.05) {
  m1 <- muBias
  m2 <- logRr - muBias
  v11 <- varMuBias
  v22 <- seLogRr^2 + v11
  v12 <- -v11
  z <- stats::qnorm(1 - alpha / 2)
  A <- m2^2 - z^2 * v22
  B <- -2 * (m1 * m2 - z^2 * v12)
  C <- m1^2 - z^2 * v11
  disc <- B^2 - 4 * A * C
  if (disc < 0) {
    return(list(lo = NA_real_, hi = NA_real_, region = if (A > 0) "empty" else "whole"))
  }
  roots <- sort((-B + c(-1, 1) * sqrt(disc)) / (2 * A))
  list(lo = roots[1], hi = roots[2], region = if (A > 0) "interior" else "exterior")
}

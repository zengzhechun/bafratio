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
#' The independence assumption \eqn{v_{12} = -v_{11}} treats the primary
#' estimate and the negative-control-derived bias estimate as independent.
#' It holds under simple random sampling of controls and a distinct primary
#' analysis, but can be **violated** under stratified/matched sampling,
#' shared covariates, or a primary estimate that itself reuses the controls
#' (e.g. a self-controlled design): there \eqn{v_{12} \neq -v_{11}} and the
#' set is too narrow. In those settings, supply an explicit covariance or
#' treat the set as a lower bound on uncertainty.
#'
#' `bf_fieller()` is an S3 generic. The low-level [bf_fieller.default()]
#' takes the quantities directly; `bf_fieller.ber()` and
#' `bf_fieller.biasratio()` extract them from a fitted object together with
#' a bootstrap (`ber_boot`), using \eqn{\mathrm{Var}(\hat\mu_B)} estimated
#' from the variance of the bootstrap resamples of the empirical-null mean.
#' The alias [fieller()] does the same.
#'
#' @param object A `ber` or `biasratio` object (for the S3 methods), or the
#'   estimated mean systematic bias \eqn{\mu_B} (for the default method).
#' @param boot A `ber_boot` object providing the bootstrap resamples of the
#'   empirical-null mean; its variance estimates \eqn{\mathrm{Var}(\hat\mu_B)}.
#' @param ... Ignored. (Present so the generic accepts the extra arguments of
#'   the `ber`/`biasratio` methods.)
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
#' # three equivalent ways to get the Fieller set
#' bf_fieller(fit$mu_bias, var(boot$mu_draws, na.rm = TRUE),
#'            sim_est$logRr, sim_est$seLogRr)
#' bf_fieller(fit, boot)
#' fieller(fit, boot)
bf_fieller <- function(object, ...) {
  UseMethod("bf_fieller")
}

#' @rdname bf_fieller
#' @export
bf_fieller.default <- function(muBias, varMuBias, logRr, seLogRr, alpha = 0.05) {
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

#' @rdname bf_fieller
#' @export
bf_fieller.ber <- function(object, boot, alpha = 0.05) {
  if (missing(boot) || is.null(boot)) {
    stop("`bf_fieller()` on a `ber` object requires the bootstrap object `boot` (class `ber_boot`).",
         call. = FALSE)
  }
  bf_fieller.default(object$mu_bias,
                     stats::var(boot$mu_draws, na.rm = TRUE),
                     object$log_rr_uncal, object$se_log_rr,
                     alpha = alpha)
}

#' @rdname bf_fieller
#' @export
bf_fieller.biasratio <- function(object, boot = object$bootstrap, alpha = 0.05) {
  bf_fieller.ber(object$estimate, boot = boot, alpha = alpha)
}

#' Fieller confidence set — object-extraction convenience
#'
#' Alias of [bf_fieller()] that always takes a fitted `ber`/`biasratio`
#' object plus a bootstrap, auto-extracting the needed quantities.
#'
#' @param object A `ber` or `biasratio` object.
#' @param boot A `ber_boot` object (defaults to `object$bootstrap` for a
#'   `biasratio`).
#' @param alpha Significance level (default 0.05 for a 95% set).
#' @param ... Ignored.
#'
#' @return See [bf_fieller()].
#' @export
#' @examples
#' fit <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
#'                    sim_nc$logRr, sim_nc$seLogRr, nBoot = 500, seed = 42)
#' fieller(fit)
fieller <- function(object, ...) {
  UseMethod("fieller")
}

#' @rdname fieller
#' @export
fieller.ber <- function(object, boot, alpha = 0.05) {
  bf_fieller.ber(object, boot = boot, alpha = alpha)
}

#' @rdname fieller
#' @export
fieller.biasratio <- function(object, boot = object$bootstrap, alpha = 0.05) {
  bf_fieller.biasratio(object, boot = boot, alpha = alpha)
}

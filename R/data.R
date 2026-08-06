#' Simulated demonstration data: healthy-adherer-like bias scenario
#'
#' A fully synthetic dataset reproducing the statistical properties of a
#' classic healthy-adherer bias scenario: a protective-looking association
#' (RR < 1) that is entirely explained by systematic error. Contains no real
#' patient data.
#'
#' The scenario: a hypothetical drug appears to reduce the risk of the
#' outcome (uncalibrated log RR = -0.184, RR = 0.83, p < 0.001). Twelve
#' negative control outcomes — conditions the drug cannot plausibly affect —
#' reveal a systematic bias toward protective associations
#' (mu_B = -0.21). After calibration the "effect" vanishes (RR = 1.02) and
#' the BER of about 8.7 shows the bias dwarfs any residual signal.
#'
#' @format
#' `sim_nc`: a data frame with 12 rows and 3 variables:
#' \describe{
#'   \item{outcome}{Negative control outcome label.}
#'   \item{logRr}{Log of the estimated relative risk.}
#'   \item{seLogRr}{Standard error of `logRr`.}
#' }
#'
#' `sim_est`: a data frame with 1 row and 3 variables:
#' \describe{
#'   \item{label}{Description of the primary estimate.}
#'   \item{logRr}{Log of the uncalibrated relative risk (-0.184).}
#'   \item{seLogRr}{Standard error (0.045).}
#' }
#'
#' @source Simulated with a fixed seed (20260806); the exact generating
#'   script is in `data-raw/make-sim-data.R` in the package source
#'   repository.
#'
#' @examples
#' data(sim_nc)
#' data(sim_est)
#' sim_nc
"sim_nc"

#' @rdname sim_nc
"sim_est"

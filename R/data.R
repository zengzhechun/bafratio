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

#' Reference calibration table for the two-layer screening
#'
#' Bias-dominated probability by bias-fraction (BF) bin, estimated from the
#' 960-condition BF estimator simulation study (manuscript v38: five-factor
#' full factorial design). Used by [ber_screen()] / [bf_screen()] for Layer 2.
#'
#' A bootstrap CI that is *narrow* (half-width <= `med_ci_width`) pins the BF
#' down well, so the true regime is less often bias-dominated than when the CI
#' is *wide*. The screening therefore reads both columns and reports the
#' conservative maximum. The caller never needs to know which column applied.
#'
#' @format A data frame with 12 rows and 3 columns:
#' \describe{
#'   \item{bf_center}{BF bin center (share of the calibrated signal that is systematic bias).}
#'   \item{p_bias_dom_narrow}{P(true regime is bias-dominated) given a narrow bootstrap CI.}
#'   \item{p_bias_dom_wide}{P(true regime is bias-dominated) given a wide bootstrap CI.}
#' }
#'
#' Attributes: `med_ci_width` (0.130, the median bootstrap-CI half-width across
#' the simulation; the narrow/wide cut point) and `source` (provenance).
#'
#' @source BF estimator simulation, manuscript v37 (640 conditions). Bundled as
#'   the default reference calibration; override via the `reliability` argument
#'   of [ber_screen()] for other simulation designs.
#'
#' @examples
#' data(bf_reliability)
#' bf_reliability
#' attr(bf_reliability, "med_ci_width")
"bf_reliability"

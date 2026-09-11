# Reporting-rule evaluator for the companion manuscript's Table 2.
#
# Why this file exists: `baf_classify()` answers "which of the three zones does
# this estimate sit in?", using the *same* thresholds (0.5 and 1/3) whether or
# not a confidence interval is supplied. The manuscript's reporting rules
# R2/R3/C1/C2 answer a different question: "does the point estimate, or the
# whole interval, stay clear of the bias-dominated threshold (0.5)?". On
# BAF = 0.45 with CI [0.30, 0.48] the two disagree: the zone classifier returns
# "mixed" (0.48 is not below 1/3) while rule R3 declares the estimate usable
# (0.48 is at or below 0.5). Both are correct answers to different questions,
# so the rules are exposed here rather than folded into `baf_classify()`.

#' Evaluate the manuscript reporting rules from a bias attribution fraction
#'
#' Applies the seven pre-specified reporting rules evaluated in the companion
#' manuscript's performance table: the five nested rules `R0`-`R4` and the two
#' stand-alone comparators `C1`, `C2`. Each rule returns whether the estimate
#' would be declared usable as effect evidence under that rule.
#'
#' @details
#' The rules, in the manuscript's notation (`BAF` = bias attribution fraction,
#' `cal_p` = calibrated p-value from [baf_estimate()], `P(BD)` = probability
#' that the true regime is bias-dominated):
#'
#' \describe{
#'   \item{`R0`}{Uncalibrated p below `alpha`. No bias correction.}
#'   \item{`R1`}{`cal_p` below `alpha` (Layer 1 only).}
#'   \item{`R2`}{`R1` and the `BAF` point estimate below `biasThreshold`.}
#'   \item{`R3`}{`R1` and the whole `BAF` interval at or below
#'     `biasThreshold`.}
#'   \item{`R4`}{`R1` and `P(BD)` below 0.15.}
#'   \item{`C1`}{`BAF` point estimate below `biasThreshold`, without Layer 1.}
#'   \item{`C2`}{The whole `BAF` interval at or below `biasThreshold`,
#'     without Layer 1.}
#' }
#'
#' Note the deliberate asymmetry that separates `R2` from `R3`: `R2` tests the
#' point estimate with a strict inequality, `R3` tests the interval's upper
#' limit with a non-strict one. This mirrors the manuscript's definitions, so
#' an estimate with `BAF = 0.5` exactly fails `R2` and passes `R3`.
#'
#' A rule is reported as `NA` when an input it needs was not supplied, rather
#' than as `FALSE`, so that a partially specified call cannot be misread as a
#' negative decision.
#'
#' @param baf Numeric scalar. The bias attribution fraction.
#' @param ciLo,ciHi Numeric scalars. Limits of the `BAF` interval. `NA`
#'   (default) leaves `R3` and `C2` undetermined.
#' @param cal_p Numeric scalar. Calibrated p-value. `NA` (default) leaves
#'   `R1`-`R4` undetermined.
#' @param p_bias_dom Numeric scalar. Probability that the true regime is
#'   bias-dominated. `NA` (default) leaves `R4` undetermined.
#' @param uncal_p Numeric scalar. Uncalibrated p-value. `NA` (default) leaves
#'   `R0` undetermined.
#' @param biasThreshold BAF at or above which an estimate is bias-dominated
#'   (default 0.5).
#' @param alpha Significance level for the p-value rules (default 0.05).
#' @param r4Threshold Upper limit of `P(BD)` for `R4` (default 0.15).
#'
#' @return A data frame with one row per rule and columns `rule`, `criterion`
#'   and `pass` (logical, or `NA` when an input was missing).
#'
#' @seealso [baf_classify()] for the three-zone classification, which answers a
#'   different question; [baf_screen()] for the two-layer screen that
#'   implements `R1` and `R4` together with the verdict bands.
#'
#' @export
#' @examples
#' # A genuine signal with a modest BAF whose interval stays below 0.5:
#' # R2 and R3 both pass, but the three-zone classifier calls it "mixed".
#' baf_rules(0.45, ciLo = 0.30, ciHi = 0.48, cal_p = 0.01, p_bias_dom = 0.12)
#' baf_classify(0.45, ciLo = 0.30, ciHi = 0.48)
#'
#' # A point estimate exactly at the threshold passes R3 but not R2.
#' baf_rules(0.50, ciLo = 0.40, ciHi = 0.50, cal_p = 0.01)$pass
baf_rules <- function(baf, ciLo = NA_real_, ciHi = NA_real_,
                     cal_p = NA_real_, p_bias_dom = NA_real_,
                     uncal_p = NA_real_,
                     biasThreshold = 0.5, alpha = 0.05, r4Threshold = 0.15) {
  ok_num <- function(x) !is.na(x) && is.finite(x)

  layer1 <- if (ok_num(cal_p)) cal_p < alpha else NA
  point  <- if (ok_num(baf)) baf < biasThreshold else NA
  whole  <- if (ok_num(ciHi)) ciHi <= biasThreshold else NA

  and2 <- function(a, b) if (is.na(a) || is.na(b)) NA else a && b

  pass <- c(
    R0 = if (ok_num(uncal_p)) uncal_p < alpha else NA,
    R1 = layer1,
    R2 = and2(layer1, point),
    R3 = and2(layer1, whole),
    R4 = and2(layer1, if (ok_num(p_bias_dom)) p_bias_dom < r4Threshold else NA),
    C1 = point,
    C2 = whole
  )

  criterion <- c(
    R0 = sprintf("uncalibrated p < %g", alpha),
    R1 = sprintf("calibrated p < %g", alpha),
    R2 = sprintf("R1 and BAF point estimate < %g", biasThreshold),
    R3 = sprintf("R1 and BAF interval upper limit <= %g", biasThreshold),
    R4 = sprintf("R1 and P(bias-dominated) < %g", r4Threshold),
    C1 = sprintf("BAF point estimate < %g", biasThreshold),
    C2 = sprintf("BAF interval upper limit <= %g", biasThreshold)
  )

  data.frame(
    rule = names(pass),
    criterion = unname(criterion),
    pass = unname(pass),
    row.names = NULL,
    stringsAsFactors = FALSE
  )
}

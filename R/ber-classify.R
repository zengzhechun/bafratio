#' Classify an effect estimate from its BER
#'
#' Three-zone classification of the credibility of an observational effect
#' estimate. When a bootstrap confidence interval is available, the
#' classification uses the interval (conservative); otherwise it falls back
#' to the point estimate.
#'
#' @param ber Numeric scalar. The bias-effect ratio.
#' @param ciLo Numeric scalar. Lower bootstrap confidence limit; `NA`
#'   (default) triggers point-estimate classification.
#' @param ciHi Numeric scalar. Upper bootstrap confidence limit; `NA`
#'   (default) triggers point-estimate classification.
#' @param biasThreshold BER above which an estimate is bias-dominated
#'   (default 1: bias exceeds calibrated signal).
#' @param effectThreshold BER below which an estimate is effect-dominated
#'   (default 0.5: calibrated signal is at least twice the bias).
#'
#' @return A character scalar: `"bias-dominated"`, `"competitive"`,
#'   `"effect-dominated"`, or `"unclassifiable"` (when `ber` is `NA`/`NaN`).
#'
#' @export
#' @examples
#' ber_classify(8.7)                        # 点估计：偏倚主导
#' ber_classify(8.7, ciLo = 2.9, ciHi = 35) # CI 下界 > 1：偏倚主导
#' ber_classify(0.03, ciLo = 0.01, ciHi = 0.1) # 效应主导
#' ber_classify(0.8, ciLo = 0.2, ciHi = 3)  # 跨阈值：势均力敌
ber_classify <- function(ber, ciLo = NA_real_, ciHi = NA_real_,
                         biasThreshold = 1, effectThreshold = 0.5) {
  if (length(ber) != 1L || is.na(ber)) return("unclassifiable")
  # 为什么有 CI 时用区间分类：点估计的落区会被抽样不确定性轻易跨越，
  # 用 CI 下/上界做判据更保守、可重复
  if (is.na(ciLo) || is.na(ciHi)) {
    if (ber > biasThreshold) return("bias-dominated")
    if (ber < effectThreshold) return("effect-dominated")
    return("competitive")
  }
  if (ciLo > biasThreshold) return("bias-dominated")
  if (ciHi < effectThreshold) return("effect-dominated")
  "competitive"
}

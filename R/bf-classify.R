#' Classify an effect estimate from its bias fraction (BF)
#'
#' Three-zone classification of the credibility of an observational effect
#' estimate on the bounded BF scale. This is the primary classification
#' rule of the package; it is equivalent to [ber_classify()] on the ratio
#' scale (BF > 0.5 equals BER > 1; BF < 1/3 equals BER < 0.5). When a
#' bootstrap confidence interval is available, the classification uses the
#' interval (conservative); otherwise it falls back to the point estimate.
#'
#' @param bf Numeric scalar. The bias fraction.
#' @param ciLo Numeric scalar. Lower bootstrap confidence limit for BF; `NA`
#'   (default) triggers point-estimate classification.
#' @param ciHi Numeric scalar. Upper bootstrap confidence limit for BF; `NA`
#'   (default) triggers point-estimate classification.
#' @param biasThreshold BF above which an estimate is bias-dominated
#'   (default 0.5: bias exceeds the residual effect).
#' @param effectThreshold BF below which an estimate is effect-dominated
#'   (default 1/3: residual effect is at least twice the bias).
#'
#' @return A character scalar: `"bias-dominated"`, `"competitive"`,
#'   `"effect-dominated"`, or `"unclassifiable"` (when `bf` is `NA`/`NaN`).
#'
#' @export
#' @examples
#' bf_classify(0.91)                         # 点估计：偏倚主导
#' bf_classify(0.91, ciLo = 0.74, ciHi = 0.99) # CI 下界 > 0.5：偏倚主导
#' bf_classify(0.45, ciLo = 0.31, ciHi = 0.53) # 跨阈值：势均力敌
#' bf_classify(0.20, ciLo = 0.10, ciHi = 0.30) # 效应主导
bf_classify <- function(bf, ciLo = NA_real_, ciHi = NA_real_,
                        biasThreshold = 0.5, effectThreshold = 1 / 3) {
  if (length(bf) != 1L || is.na(bf)) return("unclassifiable")
  # 为什么有 CI 时用区间分类：点估计的落区会被抽样不确定性轻易跨越，
  # 用 CI 下/上界做判据更保守、可重复
  if (is.na(ciLo) || is.na(ciHi)) {
    if (bf > biasThreshold) return("bias-dominated")
    if (bf < effectThreshold) return("effect-dominated")
    return("competitive")
  }
  if (ciLo > biasThreshold) return("bias-dominated")
  if (ciHi < effectThreshold) return("effect-dominated")
  "competitive"
}

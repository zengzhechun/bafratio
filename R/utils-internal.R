# Internal validation and formatting helpers (not exported).
# 为什么集中校验：ber_estimate / ber_bootstrap / ber_loo 共享同一组输入，
# 单一入口保证错误信息一致，测试只需锚定一套文案。

checkEstimateInputs <- function(logRr, seLogRr, ncLogRr, ncSeLogRr) {
  if (!is.numeric(logRr) || length(logRr) != 1L || !is.finite(logRr)) {
    stop("`logRr` must be a single finite numeric value.", call. = FALSE)
  }
  if (!is.numeric(seLogRr) || length(seLogRr) != 1L || !is.finite(seLogRr) || seLogRr <= 0) {
    stop("`seLogRr` must be a single positive numeric value.", call. = FALSE)
  }
  if (!is.numeric(ncLogRr) || !is.numeric(ncSeLogRr)) {
    stop("`ncLogRr` and `ncSeLogRr` must be numeric vectors.", call. = FALSE)
  }
  if (length(ncLogRr) != length(ncSeLogRr)) {
    stop("`ncLogRr` and `ncSeLogRr` must have the same length.", call. = FALSE)
  }
  if (length(ncLogRr) < 3L) {
    stop("At least 3 negative controls are required; 10 or more are recommended.",
         call. = FALSE)
  }
  if (any(!is.finite(ncLogRr)) || any(!is.finite(ncSeLogRr))) {
    stop("`ncLogRr` and `ncSeLogRr` must not contain NA, NaN or Inf.", call. = FALSE)
  }
  if (any(ncSeLogRr <= 0)) {
    stop("All `ncSeLogRr` values must be strictly positive.", call. = FALSE)
  }
  invisible(TRUE)
}

# 阴性对照名称解析：显式传入 > 向量自带 names > 自动生成 NC1..NCK
resolveNcNames <- function(ncNames, ncLogRr) {
  if (!is.null(ncNames)) {
    if (length(ncNames) != length(ncLogRr)) {
      stop("`ncNames` must have the same length as `ncLogRr`.", call. = FALSE)
    }
    return(as.character(ncNames))
  }
  nms <- names(ncLogRr)
  if (is.null(nms) || any(!nzchar(nms))) {
    paste0("NC", seq_along(ncLogRr))
  } else {
    nms
  }
}

# p 值格式化：临床阅读习惯（小于 0.001 统一写 "< 0.001"，否则保留三位小数）
fmtP <- function(p) {
  if (length(p) == 0L || is.na(p)) return("NA")
  if (p < 0.001) "< 0.001" else sprintf("%.3f", p)
}

fmtNum <- function(x, digits = 2L) {
  if (length(x) == 0L || is.na(x) || !is.finite(x)) return("NA")
  sprintf(paste0("%.", digits, "f"), x)
}

# 从 biasratio 总对象或 ber 子对象中提取点估计对象，绘图函数共用的入口规整
asBerObject <- function(x) {
  if (inherits(x, "biasratio")) return(x$estimate)
  if (inherits(x, "ber")) return(x)
  stop("`x` must be an object of class `ber` or `biasratio`.", call. = FALSE)
}

# 三区分类的单一内核，运行在 BER（比值）尺度上。
# bf_classify 与 ber_classify 都通过它实现，保证跨尺度严格等价：
# BF 经单调变换 bf -> bf/(1-bf) 映射到 BER，阈值与 CI 限同步变换。
# biasThreshold / effectThreshold 默认 1 / 0.5，正是 BF 默认 0.5 / 1/3 的映射。
.classify_ber <- function(ber, ciLo = NA_real_, ciHi = NA_real_,
                          biasThreshold = 1, effectThreshold = 0.5) {
  if (length(ber) != 1L || is.na(ber)) return("unclassifiable")
  # 为什么有 CI 时用区间分类：点估计的落区会被抽样不确定性轻易跨越，
  # 用 CI 下/上界做判据更保守、可重复
  if (is.na(ciLo) || is.na(ciHi)) {
    if (ber > biasThreshold) return("bias-dominated")
    if (ber < effectThreshold) return("effect-dominated")
    return("mixed")
  }
  if (ciLo > biasThreshold) return("bias-dominated")
  if (ciHi < effectThreshold) return("effect-dominated")
  "mixed"
}

# BF -> BER 的单调映射；bf >= 1 视为偏倚主导（BER = Inf）。
.to_ber <- function(bf) ifelse(bf >= 1, Inf, bf / (1 - bf))

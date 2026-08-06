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

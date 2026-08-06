# Backward-compatibility aliases (bsr_* = ber_*)
# 为什么保留：指标曾用名 BSR（bias-signal ratio），早期分析脚本使用 bsr_* 命名；
# 别名让旧脚本无需改动即可切换到本包。

#' @rdname ber_estimate
#' @export
bsr_estimate <- ber_estimate

#' @rdname ber_bootstrap
#' @export
bsr_bootstrap <- ber_bootstrap

#' @rdname ber_classify
#' @export
bsr_classify <- ber_classify

#' @rdname ber_loo
#' @export
bsr_loo <- ber_loo

#' @rdname ber_diagnostics
#' @export
bsr_diagnostics <- ber_diagnostics

#' @rdname ber_analyze
#' @export
bsr_analyze <- ber_analyze

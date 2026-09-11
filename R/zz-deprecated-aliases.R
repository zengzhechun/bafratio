# Deprecated aliases kept for backward compatibility with the 0.3.x API.
#
# 文件名的 zz- 前缀是刻意保留的，不要改成别的名字。roxygen2 在把多个文件
# 合并到同一个帮助主题时，会用「按文件名排序后第一个块」的对象名去写
# \name{}。本文件里的块只有 @rdname 指向主主题，若它排在主定义文件之前，
# roxygen 会把 \name{ber_pal} 写进 man/baf_pal.Rd 这类错位结果。让本文件
# 排在最后（zz-），主定义块就总是先被处理，\name{} 与文件名才会一致。
#
# 为什么保留这些名字：0.4.0 把包名从 biasratio 改为 bafratio，并把公开函数
# 前缀从 ber_* / bf_* / bsr_* 统一为 baf_*（bias attribution fraction 是本
# 包的主指标）。旧名继续可调用，但每次调用会给出一次弃用提示，方便已经写
# 在分析脚本里的调用平滑迁移，也避免已发布的示例代码突然报错。
#
# 两个刻意不动的名字：
#   * ber_classify() 不是别名。它按 BER 尺度接收输入（阈值 1 与 0.5），是
#     baf_classify()（按 BAF 尺度接收输入，阈值 0.5 与 1/3）的姊妹函数。
#     若把它一并改名为 baf_classify，既会与 baf_classify() 撞名，也会抹掉
#     这一层尺度区分。
#   * 对象里的字段 ber 与 ber_median 表示 BER 本身（自举中位数），是指标量
#     而非函数前缀，同样不改。对应的 bf/bf_median 已改为 baf/baf_median。

#' @rdname baf_estimate
#' @param ... Arguments passed on to [baf_estimate()].
#' @export
ber_estimate <- function(...) {
  .Deprecated("baf_estimate")
  baf_estimate(...)
}

#' @rdname baf_bootstrap
#' @param ... Arguments passed on to [baf_bootstrap()].
#' @export
ber_bootstrap <- function(...) {
  .Deprecated("baf_bootstrap")
  baf_bootstrap(...)
}

#' @rdname baf_analyze
#' @param ... Arguments passed on to [baf_analyze()].
#' @export
ber_analyze <- function(...) {
  .Deprecated("baf_analyze")
  baf_analyze(...)
}

#' @rdname baf_screen
#' @export
ber_screen <- function(...) {
  .Deprecated("baf_screen")
  baf_screen(...)
}

#' @rdname baf_loo
#' @param ... Arguments passed on to [baf_loo()].
#' @export
ber_loo <- function(...) {
  .Deprecated("baf_loo")
  baf_loo(...)
}

#' @rdname baf_diagnostics
#' @param ... Arguments passed on to [baf_diagnostics()].
#' @export
ber_diagnostics <- function(...) {
  .Deprecated("baf_diagnostics")
  baf_diagnostics(...)
}

#' @rdname baf_pal
#' @param ... Arguments passed on to [baf_pal()].
#' @export
ber_pal <- function(...) {
  .Deprecated("baf_pal")
  baf_pal(...)
}

# bf_screen() was a thin duplicate of ber_screen(): it renamed only the first
# argument. Both now point at the single baf_screen().
#' @rdname baf_screen
#' @export
bf_screen <- function(...) {
  .Deprecated("baf_screen")
  baf_screen(...)
}

#' @rdname baf_classify
#' @param ... Arguments passed on to [baf_classify()].
#' @export
bf_classify <- function(...) {
  .Deprecated("baf_classify")
  baf_classify(...)
}

#' @rdname baf_rules
#' @param ... Arguments passed on to [baf_rules()].
#' @export
bf_rules <- function(...) {
  .Deprecated("baf_rules")
  baf_rules(...)
}

#' @rdname baf_fieller
#' @export
bf_fieller <- function(...) {
  .Deprecated("baf_fieller")
  baf_fieller(...)
}

#' @rdname plot_baf_gauge
#' @param ... Arguments passed on to [plot_baf_gauge()].
#' @export
plot_bf_gauge <- function(...) {
  .Deprecated("plot_baf_gauge")
  plot_baf_gauge(...)
}

#' @rdname baf_pal
#' @param ... Arguments passed on to [baf_pal()].
#' @export
theme_biasratio <- function(...) {
  .Deprecated("theme_bafratio")
  theme_bafratio(...)
}

# bsr_* are the oldest names: the metric was once called the bias-signal
# ratio. They keep working through the same deprecation path.
#' @rdname baf_estimate
#' @param ... Arguments passed on to [baf_estimate()].
#' @export
bsr_estimate <- function(...) {
  .Deprecated("baf_estimate")
  baf_estimate(...)
}

#' @rdname baf_bootstrap
#' @param ... Arguments passed on to [baf_bootstrap()].
#' @export
bsr_bootstrap <- function(...) {
  .Deprecated("baf_bootstrap")
  baf_bootstrap(...)
}

#' @rdname ber_classify
#' @param ... Arguments passed on to [ber_classify()].
#' @export
bsr_classify <- function(...) {
  .Deprecated("ber_classify")
  ber_classify(...)
}

#' @rdname baf_loo
#' @param ... Arguments passed on to [baf_loo()].
#' @export
bsr_loo <- function(...) {
  .Deprecated("baf_loo")
  baf_loo(...)
}

#' @rdname baf_diagnostics
#' @param ... Arguments passed on to [baf_diagnostics()].
#' @export
bsr_diagnostics <- function(...) {
  .Deprecated("baf_diagnostics")
  baf_diagnostics(...)
}

#' @rdname baf_analyze
#' @param ... Arguments passed on to [baf_analyze()].
#' @export
bsr_analyze <- function(...) {
  .Deprecated("baf_analyze")
  baf_analyze(...)
}

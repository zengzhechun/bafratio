#' bafratio: Bias Attribution Fraction and Bias-Effect Ratio for Observational Studies
#'
#' Quantify residual systematic bias in observational effect estimates using
#' negative control outcomes. The package extends the OHDSI empirical
#' calibration framework from a binary calibrated p-value to a continuous,
#' interpretable diagnostic: the bias attribution fraction (BAF) on a bounded 0-1 scale,
#' with the bias-effect ratio (BER) as the auxiliary unbounded display.
#'
#' @section Main functions:
#' * [baf_estimate()] — BAF and BER point estimates
#' * [baf_bootstrap()] — bootstrap confidence intervals and bootstrap-median
#'   point estimates
#' * [ber_classify()], [baf_classify()] — three-zone classification
#' * [baf_fieller()] — Fieller confidence set for the underlying ratio
#' * [baf_loo()] — leave-one-out sensitivity analysis
#' * [baf_diagnostics()] — empirical null fit diagnostics
#' * [baf_analyze()] — full workflow in one call
#' * [baf_screen()] — two-layer screening (calibrated p + BAF/CI) with an
#'   English interpretation via [explain()]
#' * [plot_baf_gauge()], [plot_gauge()], [plot_null()],
#'   [plot_calibration()], [plot_qq()], [plot_loo()], [plot_boot()] —
#'   visualizations
#'
#' @keywords internal
#' @importFrom rlang .data
"_PACKAGE"
NULL

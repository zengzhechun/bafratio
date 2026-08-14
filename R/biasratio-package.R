#' biasratio: Bias Fraction and Bias-Effect Ratio for Observational Studies
#'
#' Quantify residual systematic bias in observational effect estimates using
#' negative control outcomes. The package extends the OHDSI empirical
#' calibration framework from a binary calibrated p-value to a continuous,
#' interpretable diagnostic: the bias fraction (BF) on a bounded 0-1 scale,
#' with the bias-effect ratio (BER) as the auxiliary unbounded display.
#'
#' @section Main functions:
#' * [ber_estimate()] — BF and BER point estimates
#' * [ber_bootstrap()] — bootstrap confidence intervals and bootstrap-median
#'   point estimates
#' * [ber_classify()], [bf_classify()] — three-zone classification
#' * [bf_fieller()] — Fieller confidence set for the underlying ratio
#' * [ber_loo()] — leave-one-out sensitivity analysis
#' * [ber_diagnostics()] — empirical null fit diagnostics
#' * [ber_analyze()] — full workflow in one call
#' * [plot_bf_gauge()], [plot_gauge()], [plot_null()],
#'   [plot_calibration()], [plot_qq()], [plot_loo()], [plot_boot()] —
#'   visualizations
#'
#' @keywords internal
#' @importFrom rlang .data
"_PACKAGE"
NULL

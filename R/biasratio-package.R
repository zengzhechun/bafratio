#' biasratio: Bias-Effect Ratio for Observational Studies
#'
#' Quantify residual systematic bias in observational effect estimates using
#' negative control outcomes. The package extends the OHDSI empirical
#' calibration framework from a binary calibrated p-value to a continuous,
#' interpretable diagnostic: the bias-effect ratio (BER).
#'
#' @section Main functions:
#' * [ber_estimate()] — BER point estimate
#' * [ber_bootstrap()] — bootstrap confidence interval
#' * [ber_classify()] — three-zone classification
#' * [ber_loo()] — leave-one-out sensitivity analysis
#' * [ber_diagnostics()] — empirical null fit diagnostics
#' * [ber_analyze()] — full workflow in one call
#' * [plot_gauge()], [plot_null()], [plot_calibration()], [plot_qq()],
#'   [plot_loo()], [plot_boot()] — visualizations
#'
#' @keywords internal
#' @importFrom rlang .data
"_PACKAGE"
NULL

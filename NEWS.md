# biasratio 0.2.0 (2026-08-14)

* The bias fraction (BF) is now the primary metric, with the bias-effect
  ratio (BER) retained as the auxiliary unbounded display
  (BF = BER / (1 + BER)). `ber_estimate()` returns both `bf` and `ber`;
  BF = 1 at a null calibrated effect, removing the need for `Inf`
  handling downstream.
* `ber_bootstrap()` now returns bootstrap-median point estimates
  (`ber_median`, `bf_median`) and the BF confidence interval
  (`bf_ci_lo`, `bf_ci_hi`), so the point estimate and the CI come from
  the same distribution and cannot diverge.
* New `bf_classify()`: three-zone classification on the BF scale
  (thresholds 0.5 and 1/3; identical partition to `ber_classify()`).
* Zone terminology: the middle zone is now named "mixed" (previously
  "competitive"); `ber_classify()` and `bf_classify()` return "mixed",
  and `ber_pal()` uses the key "mixed".
* New `bf_fieller()`: Fieller confidence set for the signed ratio
  mu_B / psi_tilde, with honest handling of near-zero denominators
  (interior / exterior / empty / whole regions).
* New `plot_bf_gauge()`: the signature gauge on the bounded 0-1 scale.
* Print methods now report BF and BER together.
* Documentation, README, and vignette rewritten around the BF-first
  narrative; NEWS.md added.

# biasratio 0.1.0

* Initial release: BER estimation, log-scale bootstrap CI, three-zone
  classification, leave-one-out analysis, diagnostics, and ggplot2
  visualizations.

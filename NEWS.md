# biasratio 0.2.1 (2026-08-23)

P0/P1 fixes from the ox-alpha code review:

* **P1-4 — `method = c("plugin", "robust")` for the calibrated p-value.**
  `ber_estimate()` now supports the small-sample correction promised by the
  companion paper's eAppendix 13. `"robust"` inflates the plug-in variance by
  the estimation variance of the empirical-null mean,
  `Var(mu_B) = [sum_k(tau_k^2 + sigma_B^2)^{-1}]^{-1}`, and references a
  Student-t distribution with `K-2` degrees of freedom. A simulation
  benchmark (now a regression test) confirms the robust Type I error is
  ~6.6% at `K = 12` (plug-in is ~11.4%). `"plugin"` remains the default to
  preserve existing behavior. The method is plumbed through `ber_analyze()`
  and `ber_loo()`.
* **P1-1 — `ber_bootstrap()` no longer re-fits the empirical null inside the
  loop.** It computes the point estimate once before the resampling and
  reuses the raw BER, avoiding a wasted MLE fit and an unguarded error path
  that could crash the whole bootstrap.
* **P1-2 — `ber_analyze()` default `seed = NULL`.** The previous hard-coded
  `seed = 42` called `set.seed()` and polluted the caller's RNG. The default
  is now `NULL` (no `set.seed`); when a seed is supplied it is localized with
  `withr::with_seed()` so it still does not leak into the global stream.
  Reproducibility is the user's responsibility unless a seed is passed.
* **P1-3 — unified classification kernel.** `bf_classify()` and
  `ber_classify()` now share a single internal kernel (BF is mapped to BER
  via `BF/(1-BF)` and the thresholds/CI limits are transformed with it), so
  the two scales are guaranteed equivalent by construction. A new test
  anchors the cross-scale equivalence.
* **P2-8 — `plot.biasratio()` now defaults to the BF gauge** (`plot_bf_gauge`)
  instead of the unbounded BER gauge, matching the paper's BF-first language
  and avoiding window-adaptation squeezing; `plot_gauge()` (BER) is retained.
* **P1-5 — `fieller()` / `bf_fieller()` object-extraction convenience.**
  `bf_fieller()` is now an S3 generic; `bf_fieller(x, boot)` and the new
  `fieller(x, boot)` auto-extract `mu_B`, `var(boot$mu_draws)`, `logRr`,
  and `seLogRr` from a `ber`/`biasratio` object, so users no longer pass
  `var(boot$mu_draws)` by hand. The documentation now states the
  `v12 = -v11` independence assumption and when it is violated.
* **P2-10 — new `vignettes/quick-start.Rmd`** (~10-minute `sim_nc` walkthrough).

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

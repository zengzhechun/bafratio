# biasratio 0.3.1 (2026-09-11)

Consistency pass against manuscript v39 (bias attribution fraction naming) and
fixes from the package-versus-manuscript audit:

* **Metric renamed to BAF.** The bias attribution fraction is now abbreviated
  `BAF` throughout the documentation, printed output and plots. Function,
  argument and column names are unchanged (`bf_classify()`, `bf_screen()`,
  `bf_center`, `bf_ci_lo`, ...), so this release is backward compatible.
* **New `bf_rules()`.** Evaluates all seven reporting rules of the companion
  manuscript's performance table (`R0`-`R4`, `C1`, `C2`) from a BAF, its
  interval and the calibrated p-value. Previously `R2`, `R3`, `C1` and `C2`
  could not be reproduced with the package, even though the Data Sharing
  statement points readers at the two-layer screening rule. Rules whose
  inputs are missing return `NA` rather than `FALSE`.
* **`bf_classify()` documents the distinction.** With a confidence interval it
  tests whether the whole interval lies inside one of the three zones (upper
  limits 1/3 and 0.5); the manuscript's `R3`/`C2` test whether the interval
  clears the bias-dominated threshold alone. Both are correct answers to
  different questions, and the documentation now says so and points to
  `bf_rules()`.
* **Stale `med_ci_width` corrected.** The documented default was 0.133 (or
  0.130) in the source, the generated `.Rd` files and `NEWS.md`; the bundled
  `bf_reliability` carries 0.1298899. The code fallback in `.screen_from_fit()`
  had the same stale literal and would have shifted the narrow/wide cut point
  had the attribute ever been missing. All now read 0.1298899.
* **Data provenance reconciled.** `R/data.R` credited `bf_reliability` to
  "manuscript v37 (640 conditions)"; the actual attribute, the generation
  script and the description all say v38 (960 conditions x 1000 replicates).
  The `@source` field now agrees.
* **Interval coverage disclosed.** The BAF interval's empirical coverage
  (71.1% overall, 58.5% narrow, 83.8% wide) is now stated in the `ber_screen()`
  and `bf_reliability` documentation, so the screening verdict is not read as
  carrying nominal 95% confidence.

# biasratio 0.3.0 (2026-08-26)

Two-layer screening API for judging whether an observational effect estimate
can serve as effect evidence (manuscript v37 discussion, 2026-08-26):

* **New `ber_screen()` / `bf_screen()` (alias).** Implements the two-layer
  screening: Layer 1 compares the calibrated p-value with a threshold
  (default 0.05) to establish a real signal; Layer 2 uses the bias attribution fraction
  `BAF` and its 95% CI to look up, in the reference simulation calibration
  `bf_reliability`, the probability that the true regime is bias-dominated,
  and maps it to a verdict band (`< 0.15` effect-evidence, `0.15-0.45` mixed /
  hypothesis-generating, `0.45-0.65` competitive / inconclusive,
  `>= 0.65` not-effect-evidence; Layer-1 fail = insufficient-evidence).
* **Conservative, internally-hidden narrow/wide logic.** The bootstrap-CI
  width is split into narrow/wide by the reference median half-width
  (`med_ci_width = 0.1298899`); both conditional P(bias-dominated) values are read
  and the reported value is the conservative maximum. Callers only supply
  `BAF` and its 95% CI; the narrow/wide distinction never reaches the user.
* **English interpretation as a first-class output.** `print.ber_screen()`
  shows the numeric decision and `explain()` returns a plain-English
  interpretation string; `summary.ber_screen()` returns a one-row data frame.
* **New dataset `bf_reliability`.** The 12-bin reference calibration
  (narrow/wide P(bias-dominated) by BAF bin) from the 960-condition BAF
  estimator simulation (manuscript v38: five-factor full factorial, 960 x 1000 = 960,000 reps), with `med_ci_width` (0.130) and `source`
  attributes. Overridable via the `reliability` argument of `ber_screen()`.
* Accepts either raw inputs or a fitted `biasratio` object (from
  `ber_analyze()`), reusing its bootstrap without recomputation.
* `Depends: R (>= 4.1)` declared.

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
  `ber_classify()` now share a single internal kernel (BAF is mapped to BER
  via `BAF/(1-BAF)` and the thresholds/CI limits are transformed with it), so
  the two scales are guaranteed equivalent by construction. A new test
  anchors the cross-scale equivalence.
* **P2-8 — `plot.biasratio()` now defaults to the BAF gauge** (`plot_bf_gauge`)
  instead of the unbounded BER gauge, matching the paper's BAF-first language
  and avoiding window-adaptation squeezing; `plot_gauge()` (BER) is retained.
* **P1-5 — `fieller()` / `bf_fieller()` object-extraction convenience.**
  `bf_fieller()` is now an S3 generic; `bf_fieller(x, boot)` and the new
  `fieller(x, boot)` auto-extract `mu_B`, `var(boot$mu_draws)`, `logRr`,
  and `seLogRr` from a `ber`/`biasratio` object, so users no longer pass
  `var(boot$mu_draws)` by hand. The documentation now states the
  `v12 = -v11` independence assumption and when it is violated.
* **P2-10 — new `vignettes/quick-start.Rmd`** (~10-minute `sim_nc` walkthrough).

# biasratio 0.2.0 (2026-08-14)

* The bias attribution fraction (BAF) is now the primary metric, with the bias-effect
  ratio (BER) retained as the auxiliary unbounded display
  (BAF = BER / (1 + BER)). `ber_estimate()` returns both `bf` and `ber`;
  BAF = 1 at a null calibrated effect, removing the need for `Inf`
  handling downstream.
* `ber_bootstrap()` now returns bootstrap-median point estimates
  (`ber_median`, `bf_median`) and the BAF confidence interval
  (`bf_ci_lo`, `bf_ci_hi`), so the point estimate and the CI come from
  the same distribution and cannot diverge.
* New `bf_classify()`: three-zone classification on the BAF scale
  (thresholds 0.5 and 1/3; identical partition to `ber_classify()`).
* Zone terminology: the middle zone is now named "mixed" (previously
  "competitive"); `ber_classify()` and `bf_classify()` return "mixed",
  and `ber_pal()` uses the key "mixed".
* New `bf_fieller()`: Fieller confidence set for the signed ratio
  mu_B / psi_tilde, with honest handling of near-zero denominators
  (interior / exterior / empty / whole regions).
* New `plot_bf_gauge()`: the signature gauge on the bounded 0-1 scale.
* Print methods now report BAF and BER together.
* Documentation, README, and vignette rewritten around the BAF-first
  narrative; NEWS.md added.

# biasratio 0.1.0

* Initial release: BER estimation, log-scale bootstrap CI, three-zone
  classification, leave-one-out analysis, diagnostics, and ggplot2
  visualizations.

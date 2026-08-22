#' Full bias-effect ratio analysis in one call
#'
#' Runs the complete workflow: BER point estimate, bootstrap confidence
#' interval, three-zone classification, empirical null diagnostics, and
#' (optionally) leave-one-out sensitivity analysis.
#'
#' @inheritParams ber_estimate
#' @inheritParams ber_bootstrap
#' @param loo Logical. Also run leave-one-out analysis? (default `FALSE`)
#' @param looBoot Bootstrap replicates per leave-one-out iteration
#'   (default 500; only used when `loo = TRUE`).
#' @param seed Optional random seed for reproducibility of the bootstrap
#'   and leave-one-out resampling. Defaults to `NULL`, in which case no seed
#'   is set and the caller's RNG is left untouched — passing a seed does
#'   **not** pollute the global RNG stream (it is localized with
#'   [withr::with_seed()]). Reproducibility is therefore the caller's
#'   responsibility unless a seed is supplied.
#'
#' @return An object of class `biasratio`: a list with components
#'   `estimate` (class `ber`), `bootstrap` (class `ber_boot`),
#'   `classification` (CI-based), `diagnostics` (class `ber_diag`),
#'   `loo` (`NULL` or class `ber_loo`), and `call`.
#'
#' @export
#' @examples
#' fit <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
#'                    sim_nc$logRr, sim_nc$seLogRr,
#'                    ncNames = sim_nc$outcome, nBoot = 500, seed = 42)
#' fit
ber_analyze <- function(logRr, seLogRr, ncLogRr, ncSeLogRr, ncNames = NULL,
                        nBoot = 2000, seed = NULL, level = 0.95,
                        loo = FALSE, looBoot = 500,
                        method = c("plugin", "robust")) {
  method <- match.arg(method)
  ncNames <- resolveNcNames(ncNames, ncLogRr)

  estimate <- ber_estimate(logRr, seLogRr, ncLogRr, ncSeLogRr,
                           ncNames = ncNames, method = method)
  bootstrap <- ber_bootstrap(logRr, seLogRr, ncLogRr, ncSeLogRr,
                             nBoot = nBoot, seed = seed, level = level)
  classification <- ber_classify(estimate$ber, bootstrap$ci_lo, bootstrap$ci_hi)
  diagnostics <- ber_diagnostics(ncLogRr, ncSeLogRr, ncNames = ncNames)
  looDf <- if (isTRUE(loo)) {
    ber_loo(logRr, seLogRr, ncLogRr, ncSeLogRr, ncNames = ncNames,
            nBoot = looBoot, seed = seed, method = method)
  } else {
    NULL
  }

  structure(
    list(
      estimate = estimate,
      bootstrap = bootstrap,
      classification = classification,
      diagnostics = diagnostics,
      loo = looDf,
      call = match.call()
    ),
    class = "biasratio"
  )
}

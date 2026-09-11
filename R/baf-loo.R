#' Leave-one-out sensitivity analysis for the BER
#'
#' Recomputes the BER (and optionally its bootstrap CI) after excluding each
#' negative control in turn. Identifies whether the conclusion depends on a
#' single influential control.
#'
#' @inheritParams baf_estimate
#' @param nBoot Bootstrap replicates per exclusion (default 500). Set to 0
#'   to skip confidence intervals (point estimates only).
#' @param seed Optional random seed. When supplied, iteration `i` uses
#'   `seed + i`, so results are reproducible without stream coupling. The
#'   seed is localized by [baf_bootstrap()] and does not pollute the global
#'   RNG stream.
#'
#' @return A data frame of class `baf_loo` with one row per excluded
#'   negative control: `excluded`, `ber`, `ci_lo`, `ci_hi`, `classification`.
#'
#' @export
#' @examples
#' loo <- baf_loo(sim_est$logRr, sim_est$seLogRr,
#'                sim_nc$logRr, sim_nc$seLogRr,
#'                ncNames = sim_nc$outcome, nBoot = 100, seed = 1)
#' loo
baf_loo <- function(logRr, seLogRr, ncLogRr, ncSeLogRr, ncNames = NULL,
                    nBoot = 500, seed = NULL,
                    method = c("plugin", "robust")) {
  method <- match.arg(method)
  checkEstimateInputs(logRr, seLogRr, ncLogRr, ncSeLogRr)
  ncNames <- resolveNcNames(ncNames, ncLogRr)
  K <- length(ncLogRr)
  # 剔除一个后仍需满足 fitNull 的最小样本量
  if (K < 4L) {
    stop("Leave-one-out analysis requires at least 4 negative controls.",
         call. = FALSE)
  }

  berVec <- ciLoVec <- ciHiVec <- rep(NA_real_, K)
  classVec <- character(K)

  for (i in seq_len(K)) {
    est <- baf_estimate(logRr, seLogRr, ncLogRr[-i], ncSeLogRr[-i],
                       method = method)
    berVec[i] <- est$ber
    if (nBoot > 0) {
      boot <- baf_bootstrap(
        logRr, seLogRr, ncLogRr[-i], ncSeLogRr[-i],
        nBoot = nBoot,
        seed = if (!is.null(seed)) seed + i else NULL
      )
      ciLoVec[i] <- boot$ci_lo
      ciHiVec[i] <- boot$ci_hi
    }
    classVec[i] <- ber_classify(est$ber, ciLoVec[i], ciHiVec[i])
  }

  structure(
    data.frame(
      excluded = ncNames,
      ber = berVec,
      ci_lo = ciLoVec,
      ci_hi = ciHiVec,
      classification = classVec,
      stringsAsFactors = FALSE
    ),
    class = c("baf_loo", "data.frame")
  )
}

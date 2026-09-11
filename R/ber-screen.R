# Two-layer screening: decide whether an observational effect estimate can
# serve as effect evidence.
#
# Design originated in the manuscript v37 discussion (2026-08-26); the data
# provenance is the v38 simulation study, see `bf_reliability`.
#   Layer 1 -- Signal existence. A calibrated p-value (OHDSI empirical
#     calibration) answers "is there a signal distinct from chance?". Below
#     `cal_p_threshold` (default 0.05) a real signal is established; otherwise
#     the result cannot yet be used as effect evidence.
#   Layer 2 -- Bias share. Conditional on a real signal, the bias attribution fraction
#     BAF in [0,1] and its 95% CI quantify how much of the calibrated signal is
#     systematic bias. The bootstrap-CI *width* is itself informative: a wide
#     CI means the true BAF is poorly pinned down, so the probability that the
#     true regime is bias-dominated is higher. We therefore look up, from the
#     reference simulation calibration `bf_reliability`, both the narrow-CI and
#     wide-CI conditional probabilities and report the conservative max. The
#     verdict bands turn that probability into an actionable recommendation.
#
# The narrow/wide split is an INTERNAL algorithm detail: the caller only
# supplies BAF and its 95% CI, and the reported P(bias-dominated) is already the
# conservative (max) value, so the clinician never needs to know which column
# applied. This mirrors the clinical algorithm document, where the narrow/wide
# distinction is hidden inside the procedure.

#' Two-layer screening of an observational effect estimate
#'
#' Decides whether an observational effect estimate can serve as *effect
#' evidence*, using a two-layer procedure:
#'
#' 1. **Layer 1 (signal existence).** The calibrated p-value (`cal_p`) from
#'    [ber_estimate()] is compared with `cal_p_threshold` (default 0.05). A
#'    calibrated p at or above the threshold means no signal distinct from
#'    chance is established, so the bias screening in Layer 2 is not entered
#'    and the verdict is `"insufficient-evidence"`.
#' 2. **Layer 2 (bias share).** Conditional on a real signal, the bias attribution fraction
#'    `BAF` and its 95% CI are used to look up, in the reference simulation
#'    calibration [bf_reliability], the probability that the *true* regime is
#'    bias-dominated. Because a wide CI implies a poorly pinned-down BAF, both
#'    the narrow-CI and wide-CI conditional probabilities are read and the
#'    conservative maximum is reported as `P(bias-dominated)`. The verdict then
#'    follows fixed bands:
#'    `< 0.15` effect-evidence, `0.15-0.45` mixed / hypothesis-generating,
#'    `0.45-0.65` competitive / inconclusive, `>= 0.65` not-effect-evidence.
#'
#' The function returns a `ber_screen` object whose `print`/`summary` show the
#' numeric decision and whose `explain()` method returns a plain-English
#' interpretation. When the BAF 95% CI is truncated at the 0 or 1 boundary, the
#' usable one-sided half-interval is used for the width classification.
#'
#' **Interval coverage caveat.** The `BAF` interval underlying both layers is
#' an approximate (bootstrap / posterior) interval whose empirical coverage in
#' the reference simulation is below the nominal 95% (71.1% overall, 58.5%
#' narrow, 83.8% wide; companion manuscript, v39). The verdict bands therefore
#' carry more uncertainty than a nominal 95% interval implies. See the
#' [bf_reliability] reference table this screening reads.
#'
#' The two-layer screen implements rules `R1` and `R4` of the companion
#' manuscript's rule table. The remaining rules, including the interval-based
#' `R3`/`C2`, are available from [bf_rules()].
#'
#' @param logRr Either a `biasratio` object (from [ber_analyze()], which
#'   already contains the estimate and bootstrap) or, in the default method,
#'   the numeric log of the uncalibrated effect estimate (the primary
#'   exposure-outcome pair). When a `biasratio` object is supplied, the
#'   remaining arguments are ignored.
#' @param seLogRr Numeric scalar. Standard error of `logRr` (default method).
#' @param ncLogRr Numeric vector. Log effect estimates of the negative
#'   controls (default method).
#' @param ncSeLogRr Numeric vector. Standard errors of `ncLogRr` (default
#'   method).
#' @param ncNames Optional character vector of negative-control labels.
#' @param nBoot Bootstrap replicates for the BAF 95% CI (default method only;
#'   ignored when a `biasratio` object is supplied, since it already has the
#'   bootstrap).
#' @param seed Optional random seed for the bootstrap (default method).
#' @param level Confidence level for the BAF CI (default 0.95).
#' @param method Calibrated p method, `"plugin"` (default) or `"robust"`
#'   (passed to [ber_estimate()] in the default method).
#' @param reliability Reference calibration table (default [bf_reliability]).
#'   A data frame with columns `bf_center`, `p_bias_dom_narrow`,
#'   `p_bias_dom_wide`; the median CI half-width is read from its
#'   `med_ci_width` attribute (default 0.133).
#' @param cal_p_threshold Layer-1 threshold for the calibrated p-value
#'   (default 0.05).
#' @param ... Ignored.
#'
#' @return An object of class `ber_screen`: a list with
#'   \describe{
#'     \item{layer1}{list with `cal_p`, `threshold`, `passed`.}
#'     \item{layer2}{list with `bf`, `bf_ci_lo`, `bf_ci_hi`,
#'       `ci_half_width`, `ci_class` (`"narrow"`/`"wide"`), `clipped`
#'       (logical, TRUE when the CI hit the 0/1 boundary), `bin` (the matched
#'       row of `reliability`), `p_bias_dom_narrow`, `p_bias_dom_wide`, and
#'       `p_bias_dom` (the conservative maximum).}
#'     \item{verdict}{list with `code`, `label`, `explanation` (English).}
#'     \item{reliability_source}{Provenance of the calibration table used.}
#'   }
#'
#' @seealso [ber_analyze()] for the full workflow, [ber_classify()] /
#'   [bf_classify()] for the simpler three-zone (BAF-only) classification,
#'   [bf_rules()] for the full manuscript rule table, and [explain()] for the
#'   plain-English interpretation.
#'
#' @export
#' @examples
#' # raw inputs
#' sc <- ber_screen(sim_est$logRr, sim_est$seLogRr,
#'                  sim_nc$logRr, sim_nc$seLogRr, nBoot = 500, seed = 42)
#' sc
#' explain(sc)
#'
#' # or screen an existing ber_analyze() fit
#' fit <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
#'                    sim_nc$logRr, sim_nc$seLogRr, nBoot = 500, seed = 42)
#' ber_screen(fit)
ber_screen <- function(logRr, seLogRr, ncLogRr, ncSeLogRr, ncNames = NULL,
                       nBoot = 2000, seed = NULL, level = 0.95,
                       method = c("plugin", "robust"),
                       reliability = bf_reliability,
                       cal_p_threshold = 0.05, ...) {
  # Accept a fitted biasratio object transparently: extract its estimate and
  # bootstrap and screen those, avoiding any recomputation.
  if (inherits(logRr, "biasratio")) {
    obj <- logRr
    est <- obj$estimate
    boot <- obj$bootstrap
    if (is.null(boot)) {
      stop("`ber_screen()` on a `biasratio` object needs the bootstrap component; ",
           "re-run `ber_analyze()` with `nBoot >= 1`.", call. = FALSE)
    }
    return(.screen_from_fit(est, boot, reliability, cal_p_threshold))
  }
  method <- match.arg(method)
  est <- ber_estimate(logRr, seLogRr, ncLogRr, ncSeLogRr,
                      ncNames = ncNames, method = method)
  boot <- ber_bootstrap(logRr, seLogRr, ncLogRr, ncSeLogRr,
                         nBoot = nBoot, seed = seed, level = level)
  .screen_from_fit(est, boot, reliability, cal_p_threshold)
}

#' @rdname ber_screen
#' @export
bf_screen <- function(logRr, ...) ber_screen(logRr, ...)

# ---- internal helpers -------------------------------------------------------

# Nearest-bin lookup of P(bias-dominated) from the reference calibration.
.lookup_pbd <- function(bf, reliability) {
  centers <- reliability$bf_center
  i <- which.min(abs(centers - bf))
  list(
    bin = i,
    bf_center = centers[i],
    p_narrow = reliability$p_bias_dom_narrow[i],
    p_wide = reliability$p_bias_dom_wide[i]
  )
}

# Verdict band from the conservative P(bias-dominated) and the Layer-1 result.
.verdict_band <- function(p_bias_dom, layer1_pass) {
  if (!layer1_pass) {
    return(list(
      code = "insufficient-evidence",
      label = "INSUFFICIENT EVIDENCE",
      explanation = paste0(
        "A real signal was not established at Layer 1 (calibrated p at or ",
        "above the threshold), so the result cannot yet be used as effect ",
        "evidence. Strengthen the negative controls or collect more data, ",
        "then re-screen. Do not interpret the association as an effect."
      )
    ))
  }
  if (p_bias_dom < 0.15) {
    return(list(
      code = "effect-evidence",
      label = "EFFECT EVIDENCE",
      explanation = paste0(
        "The estimated bias attribution fraction is small and the calibrated signal ",
        "clearly dominates: after accounting for estimation uncertainty, the ",
        "probability that the true regime is bias-dominated is low. The ",
        "result may be reported as effect evidence, while still disclosing ",
        "the residual systematic-error share."
      )
    ))
  }
  if (p_bias_dom < 0.45) {
    return(list(
      code = "mixed",
      label = "MIXED / HYPOTHESIS-GENERATING",
      explanation = paste0(
        "The bias attribution fraction is modest and signal and bias are of comparable ",
        "magnitude. Treat the result as hypothesis-generating rather than ",
        "confirmed effect evidence, and seek independent replication before ",
        "any clinical or policy claim."
      )
    ))
  }
  if (p_bias_dom < 0.65) {
    return(list(
      code = "competitive",
      label = "COMPETITIVE / INCONCLUSIVE",
      explanation = paste0(
        "The bias attribution fraction is high and bias and signal are roughly evenly ",
        "matched. No firm conclusion can be drawn; the result is not suitable ",
        "as effect evidence without additional, independent evidence."
      )
    ))
  }
  list(
    code = "not-effect-evidence",
    label = "NOT EFFECT EVIDENCE",
    explanation = paste0(
      "The estimated bias attribution fraction is large and, after accounting for ",
      "estimation uncertainty, the probability that the true regime is ",
      "bias-dominated is high. The observed association is most likely an ",
      "artifact of residual systematic error and should not be reported as ",
      "an effect."
    )
  )
}

# Core screening from a fitted estimate + bootstrap (shared by both entry points).
.screen_from_fit <- function(est, boot, reliability, cal_p_threshold) {
  cal_p <- est$cal_p
  layer1_pass <- is.finite(cal_p) && cal_p < cal_p_threshold

  bf <- boot$bf_median
  bf_lo <- boot$bf_ci_lo
  bf_hi <- boot$bf_ci_hi
  ci_half <- (bf_hi - bf_lo) / 2
  med_ci_width <- attr(reliability, "med_ci_width", exact = TRUE)
  # Fallback equals the bundled reference value; kept in sync with
  # data-raw/make-reliability.R so a missing attribute cannot silently shift
  # the narrow/wide cut point.
  if (is.null(med_ci_width) || !is.finite(med_ci_width)) med_ci_width <- 0.1298899
  ci_class <- if (ci_half <= med_ci_width) "narrow" else "wide"
  # BAF endpoint clipping: when the CI touches 0 or 1 the monotone transform has
  # already produced the usable one-sided region, and (hi - lo) / 2 is exactly
  # that usable half-interval.
  clipped <- (bf_lo <= 0) || (bf_hi >= 1)

  lk <- .lookup_pbd(bf, reliability)
  p_bias_dom <- max(lk$p_narrow, lk$p_wide)  # conservative

  verdict <- .verdict_band(p_bias_dom, layer1_pass)
  src <- attr(reliability, "source", exact = TRUE)

  structure(
    list(
      layer1 = list(cal_p = cal_p, threshold = cal_p_threshold,
                    passed = layer1_pass),
      layer2 = list(bf = bf, bf_ci_lo = bf_lo, bf_ci_hi = bf_hi,
                    ci_half_width = ci_half, ci_class = ci_class,
                    clipped = clipped, bin = lk$bin, bf_center = lk$bf_center,
                    p_bias_dom_narrow = lk$p_narrow,
                    p_bias_dom_wide = lk$p_wide,
                    p_bias_dom = p_bias_dom),
      verdict = verdict,
      reliability_source = if (is.null(src)) "bf_reliability (default)" else src
    ),
    class = "ber_screen"
  )
}

# Plain-English explanation string for a ber_screen object.
.screen_explanation <- function(x) {
  L1 <- x$layer1
  L2 <- x$layer2
  V <- x$verdict
  out <- character(0)
  # Layer 1 meaning: is there a real signal at all?
  out <- c(out, paste0(
    "Layer 1, signal existence: the calibrated p-value asks whether the ",
    "observed association is distinguishable from chance after correcting ",
    "for systematic error. Calibrated p = ", fmtP(L1$cal_p),
    " versus the threshold ", fmtNum(L1$threshold, 2), ". ",
    if (L1$passed) {
      "A real signal is established, so we proceed to Layer 2."
    } else {
      "No real signal is established, so the result cannot yet be used as effect evidence."
    }
  ))
  if (!L1$passed) {
    out <- c(out, V$explanation)
    return(paste(out, collapse = " "))
  }
  clipped_note <- if (L2$clipped) {
    " The 95% CI is truncated at the 0/1 boundary, so the reported interval is the usable one-sided region."
  } else ""
  # Layer 2 meaning: given a real signal, how much of it is bias?
  out <- c(out, paste0(
    "Layer 2, bias share: given a real signal, the bias attribution fraction BAF = ",
    fmtNum(L2$bf, 2), " with 95% CI [", fmtNum(L2$bf_ci_lo, 2), ", ",
    fmtNum(L2$bf_ci_hi, 2), "] measures the share of the calibrated signal ",
    "that is systematic bias.", clipped_note
  ))
  out <- c(out, paste0(
    "After accounting for estimation uncertainty, the conservative ",
    "probability that the true regime is bias-dominated is P = ",
    fmtNum(100 * L2$p_bias_dom, 1), "%. This single number already folds ",
    "in how wide the confidence interval is, so the clinician does not need ",
    "to interpret narrow versus wide intervals."
  ))
  out <- c(out, paste0("Verdict: ", V$label, ". ", V$explanation))
  paste(out, collapse = " ")
}

#' @export
print.ber_screen <- function(x, ...) {
  L1 <- x$layer1
  L2 <- x$layer2
  V <- x$verdict
  cat("biasratio two-layer screening\n")
  cat(strrep("=", 56), "\n", sep = "")
  cat(sprintf("Layer 1  calibrated p = %s  (threshold %s)  ->  %s\n",
              fmtP(L1$cal_p), fmtNum(L1$threshold, 2),
              if (L1$passed) "signal present" else "NO signal"))
  if (!L1$passed) {
    cat(strrep("-", 56), "\n", sep = "")
    cat("Verdict: ", V$label, "\n", sep = "")
    cat("\n", .screen_explanation(x), "\n", sep = "")
    return(invisible(x))
  }
  cat(sprintf("Layer 2  BAF = %s  [%s, %s]\n",
              fmtNum(L2$bf, 2), fmtNum(L2$bf_ci_lo, 2), fmtNum(L2$bf_ci_hi, 2)))
  cat(sprintf("         P(bias-dominated, conservative) = %.1f%%\n",
              100 * L2$p_bias_dom))
  cat(strrep("-", 56), "\n", sep = "")
  cat("Verdict: ", V$label, "  (", V$code, ")\n", sep = "")
  cat("\n", .screen_explanation(x), "\n", sep = "")
  invisible(x)
}

#' @export
summary.ber_screen <- function(object, ...) {
  L1 <- object$layer1
  L2 <- object$layer2
  V <- object$verdict
  structure(
    list(
      cal_p = L1$cal_p,
      layer1_pass = L1$passed,
      bf = L2$bf,
      bf_ci_lo = L2$bf_ci_lo,
      bf_ci_hi = L2$bf_ci_hi,
      p_bias_dom = L2$p_bias_dom,
      verdict_code = V$code,
      verdict_label = V$label
    ),
    class = "data.frame",
    row.names = "screen"
  )
}

#' Plain-English interpretation of a screening result
#'
#' Returns the human-readable explanation of a [ber_screen()] result. The
#' printed `ber_screen` object also shows this text; `explain()` gives the
#' caller the string for inclusion in reports or downstream tooling.
#'
#' @param object A `ber_screen` object.
#' @param ... Ignored.
#'
#' @return A character string with the English interpretation.
#'
#' @export
#' @examples
#' sc <- ber_screen(sim_est$logRr, sim_est$seLogRr,
#'                  sim_nc$logRr, sim_nc$seLogRr, nBoot = 500, seed = 42)
#' explain(sc)
explain <- function(object, ...) UseMethod("explain")

#' @rdname explain
#' @export
explain.ber_screen <- function(object, ...) .screen_explanation(object)

# ---- visualization ---------------------------------------------------------

#' Visualize a two-layer screening result
#'
#' Draws the [ber_screen()] decision as a two-layer diagram: the top panel
#' shows Layer 1 (whether the calibrated p-value clears the signal threshold),
#' the bottom panel shows Layer 2 (the bias attribution fraction BAF and its 95% CI on the
#' bounded 0-1 scale, colored by the verdict). The conservative
#' P(bias-dominated) is reported in the subtitle, so the clinician reads the
#' conclusion directly without interpreting narrow versus wide confidence
#' intervals.
#'
#' @param x A `ber_screen` object.
#' @param ... Ignored.
#'
#' @return A `ggplot` object.
#' @export
#' @examples
#' sc <- ber_screen(sim_est$logRr, sim_est$seLogRr,
#'                  sim_nc$logRr, sim_nc$seLogRr, nBoot = 500, seed = 42)
#' plot(sc)
plot.ber_screen <- function(x, ...) {
  L1 <- x$layer1
  L2 <- x$layer2
  V <- x$verdict

  vcol <- switch(V$code,
    "effect-evidence"        = "#1E8449",
    "mixed"                  = "#E67E22",
    "competitive"            = "#C0392B",
    "not-effect-evidence"    = "#C0392B",
    "insufficient-evidence"  = "#7F8C8D",
    "#7F8C8D")
  pal <- ber_pal()

  thr <- L1$threshold
  cal_p_pt <- min(max(L1$cal_p, 0.001), 0.999)
  cal_p_lbl_x <- max(0.04, min(L1$cal_p, 0.96))
  bf_pt <- min(max(L2$bf, 0.001), 0.999)
  bf_lbl_x <- max(0.06, min(L2$bf, 0.94))
  mid1 <- (0.60 + 0.95) / 2
  mid2 <- (0.05 + 0.40) / 2

  p <- ggplot2::ggplot() +
    # ---- Layer 1: calibrated p gate ----
    ggplot2::annotate("rect", xmin = 0, xmax = thr, ymin = 0.60, ymax = 0.95,
                      fill = "#1E8449", alpha = 0.12) +
    ggplot2::annotate("rect", xmin = thr, xmax = 1, ymin = 0.60, ymax = 0.95,
                      fill = "#BDC3C7", alpha = 0.30) +
    ggplot2::annotate("segment", x = thr, xend = thr, y = 0.60, yend = 0.95,
                      color = "grey45", linetype = "dashed") +
    ggplot2::annotate("text", x = thr / 2, y = 0.93,
                      label = "signal established", color = "#1E8449",
                      size = 3, hjust = 0.5, vjust = 1) +
    ggplot2::annotate("text", x = (1 + thr) / 2, y = 0.93,
                      label = "no signal", color = "#7F8C8D",
                      size = 3, hjust = 0.5, vjust = 1) +
    ggplot2::annotate("point", x = cal_p_pt, y = mid1,
                      color = if (L1$passed) "#1E8449" else "#7F8C8D", size = 6) +
    ggplot2::annotate("text", x = cal_p_lbl_x, y = 0.585,
                      label = sprintf("calibrated p = %s", fmtP(L1$cal_p)),
                      size = 3.4, fontface = "bold", hjust = 0.5, vjust = 1) +
    # ---- Layer 2: BAF gauge ----
    ggplot2::annotate("rect", xmin = 0, xmax = 1/3, ymin = 0.05, ymax = 0.40,
                      fill = pal["effect-dominated"], alpha = 0.12) +
    ggplot2::annotate("rect", xmin = 1/3, xmax = 0.5, ymin = 0.05, ymax = 0.40,
                      fill = pal["mixed"], alpha = 0.12) +
    ggplot2::annotate("rect", xmin = 0.5, xmax = 1, ymin = 0.05, ymax = 0.40,
                      fill = pal["bias-dominated"], alpha = 0.12) +
    ggplot2::annotate("segment", x = 1/3, xend = 1/3, y = 0.05, yend = 0.40,
                      color = "grey45", linetype = "dashed") +
    ggplot2::annotate("segment", x = 0.5, xend = 0.5, y = 0.05, yend = 0.40,
                      color = "grey45", linetype = "dashed") +
    ggplot2::annotate("segment", x = L2$bf_ci_lo, xend = L2$bf_ci_hi,
                      y = mid2, yend = mid2, color = vcol, linewidth = 2) +
    ggplot2::annotate("segment", x = L2$bf_ci_lo, xend = L2$bf_ci_lo,
                      y = mid2 - 0.03, yend = mid2 + 0.03, color = vcol, linewidth = 1) +
    ggplot2::annotate("segment", x = L2$bf_ci_hi, xend = L2$bf_ci_hi,
                      y = mid2 - 0.03, yend = mid2 + 0.03, color = vcol, linewidth = 1) +
    ggplot2::annotate("point", x = bf_pt, y = mid2, color = vcol, size = 6) +
    ggplot2::annotate("text", x = bf_lbl_x, y = 0.025,
                      label = sprintf("BAF = %s  [95%% CI %s, %s]",
                                      fmtNum(L2$bf, 2),
                                      fmtNum(L2$bf_ci_lo, 2),
                                      fmtNum(L2$bf_ci_hi, 2)),
                      size = 3.4, fontface = "bold", hjust = 0.5, vjust = 1) +
    # ---- layer labels ----
    ggplot2::annotate("text", x = 1.03, y = mid1,
                      label = "Layer 1\nsignal", size = 3, hjust = 0,
                      color = "grey30") +
    ggplot2::annotate("text", x = 1.03, y = mid2,
                      label = "Layer 2\nbias share", size = 3, hjust = 0,
                      color = "grey30") +
    # ---- verdict read-out in the gap ----
    ggplot2::annotate("text", x = 0.5, y = 0.52,
                      label = V$label, color = vcol,
                      fontface = "bold", size = 5, hjust = 0.5) +
    ggplot2::scale_x_continuous(limits = c(-0.02, 1.30),
                                breaks = c(0, 1/3, 0.5, 0.75, 1),
                                labels = c("0", "1/3", "0.5", "0.75", "1")) +
    ggplot2::scale_y_continuous(limits = c(-0.06, 1.02)) +
    ggplot2::labs(
      title = "biasratio two-layer screening",
      subtitle = sprintf("Conservative P(bias-dominated) = %.1f%%  ->  %s",
                         100 * L2$p_bias_dom, V$label),
      x = "bias attribution fraction BAF (Layer 2) / calibrated p (Layer 1)", y = NULL,
      caption = paste0("Layer 1 asks 'is there a real signal?'. ",
                       "Layer 2 asks 'how much of it is bias?'. ",
                       "Narrow/wide CI is folded into the conservative P.")
    ) +
    theme_biasratio() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.title.y = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      plot.title = ggplot2::element_text(face = "bold", size = 12),
      plot.subtitle = ggplot2::element_text(color = vcol, size = 10)
    )
  p
}

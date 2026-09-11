#' BAF gauge: point estimate and CI on the bounded 0-1 scale
#'
#' The signature plot of the v0.2.0 API. Shows the bias attribution fraction (BAF) and its
#' bootstrap CI on the bounded unit interval, divided into the three
#' credibility zones: effect-dominated (< 1/3), mixed (1/3-0.5), and
#' bias-dominated (> 0.5). BAF values near 1 should be read as signal
#' saturation by bias, not as precise fractions.
#'
#' @param x An object of class `biasratio` (uses its bootstrap CI and median
#'   point estimate) or `ber` (point estimate only).
#' @param digits Rounding for annotations.
#'
#' @return A `ggplot` object.
#' @export
#' @examples
#' fit <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
#'                    sim_nc$logRr, sim_nc$seLogRr, nBoot = 500, seed = 42)
#' plot_bf_gauge(fit)
plot_bf_gauge <- function(x, digits = 2) {
  est <- asBerObject(x)
  hasCi <- inherits(x, "biasratio")
  bf <- if (hasCi) x$bootstrap$bf_median else est$bf
  bfLo <- if (hasCi) x$bootstrap$bf_ci_lo else NA_real_
  bfHi <- if (hasCi) x$bootstrap$bf_ci_hi else NA_real_
  cls <- if (hasCi) x$classification else est$classification
  clsCol <- classColor(cls)
  pal <- ber_pal()

  zoneDf <- data.frame(
    xmin = c(0, 1 / 3, 0.5),
    xmax = c(1 / 3, 0.5, 1),
    zone = c("effect-dominated", "mixed", "bias-dominated"),
    xmid = c(1 / 6, (1 / 3 + 0.5) / 2, 0.75)
  )

  subtitle <- if (hasCi) {
    sprintf("BAF = %s,  %d%% CI [%s, %s]  ->  %s",
            fmtNum(bf, digits), round(x$bootstrap$level * 100),
            fmtNum(bfLo, digits), fmtNum(bfHi, digits), cls)
  } else {
    sprintf("BAF = %s  ->  %s (point estimate; run ber_bootstrap for a CI)",
            fmtNum(bf, digits), cls)
  }

  p <- ggplot2::ggplot() +
    ggplot2::annotate("rect",
                      xmin = zoneDf$xmin, xmax = zoneDf$xmax,
                      ymin = -0.32, ymax = 0.32,
                      fill = pal[zoneDf$zone], alpha = 0.13) +
    ggplot2::annotate("text",
                      x = zoneDf$xmid, y = 0.45, label = zoneDf$zone,
                      color = pal[zoneDf$zone], fontface = "bold",
                      size = 3.2) +
    ggplot2::annotate("segment",
                      x = c(1 / 3, 0.5), xend = c(1 / 3, 0.5),
                      y = -0.32, yend = 0.32,
                      linetype = "dashed", color = "grey55") +
    ggplot2::annotate("text", x = bf, y = -0.5,
                      label = paste0("BAF = ", fmtNum(bf, digits)),
                      color = clsCol, fontface = "bold", size = 4.2) +
    ggplot2::geom_point(ggplot2::aes(x = bf, y = 0),
                        color = clsCol, size = 5.5) +
    ggplot2::scale_x_continuous(
      breaks = c(0, 1 / 3, 0.5, 0.75, 1),
      labels = c("0", "1/3", "0.5", "0.75", "1"),
      limits = c(0, 1)
    ) +
    ggplot2::coord_cartesian(ylim = c(-0.66, 0.74)) +
    ggplot2::labs(
      title = "Bias fraction gauge",
      subtitle = subtitle,
      x = "BAF = |mu_B| / (|mu_B| + |calibrated effect|)", y = NULL,
      caption = "Zones: BAF < 1/3 effect-dominated | 1/3-0.5 mixed | > 0.5 bias-dominated"
    ) +
    theme_biasratio() +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.title.y = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank()
    )

  if (hasCi) {
    p <- p + ggplot2::annotate("errorbar",
                               xmin = bfLo, xmax = bfHi, y = 0,
                               orientation = "y",
                               width = 0.15, linewidth = 1.1, color = clsCol)
  }
  p
}

#' Color palette and ggplot2 theme for bafratio
#'
#' `baf_pal()` returns the canonical three-zone colors used across all
#' bafratio plots: red for bias-dominated, amber for mixed, green for
#' effect-dominated. Zone membership is always also encoded by position and
#' text labels, so the plots remain readable for color-blind readers.
#'
#' @return `baf_pal()`: a named character vector of hex colors.
#'   `theme_bafratio()`: a ggplot2 theme.
#'
#' @export
#' @examples
#' baf_pal()
baf_pal <- function() {
  c(
    "bias-dominated" = "#C0392B",
    "mixed" = "#E67E22",
    "effect-dominated" = "#1E8449"
  )
}

# 分类名到颜色的安全查找；unclassifiable 回退为墨色
classColor <- function(classification) {
  pal <- baf_pal()
  if (length(classification) == 0L || is.na(classification) ||
      !classification %in% names(pal)) {
    return("#1B2A41")
  }
  unname(pal[classification])
}

#' @rdname baf_pal
#' @param baseSize Base font size in points.
#' @export
theme_bafratio <- function(baseSize = 12) {
  ggplot2::theme_minimal(base_size = baseSize) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = ggplot2::rel(1.05)),
      plot.subtitle = ggplot2::element_text(color = "grey30", size = ggplot2::rel(0.9)),
      plot.caption = ggplot2::element_text(color = "grey45", size = ggplot2::rel(0.75)),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom"
    )
}

#' A sleek theme for ggplot2
#'
#' A simple theme for ggplot2 that loosely resembles nicely themed plots from
#' base graphics.
#'
#' This version has parameters for a transparent background. To save a
#' transparent plot, you can use ggsave with the added specification
#' bg = "transparent".
#'
#' @param base_size Base size
#' @param base_family Base family
#'
#' @importFrom ggplot2 element_text element_rect element_blank theme_light theme
#'   rel
#' @importFrom grid unit
#'
#' @examples
#' p <- ggplot2::ggplot(mtcars) +
#'   ggplot2::geom_point(ggplot2::aes(x = wt, y = mpg, colour = factor(gear))) +
#'   ggplot2::facet_wrap(~am)
#' p + theme_sleek()
#'
#' @export

theme_sleek_transparent <- function(base_size = 11, base_family = "") {
  half_line <- base_size/2
  theme_light(base_size = base_size, base_family = base_family) +
    theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      axis.ticks.length = unit(half_line / 2.2, "pt"),
      strip.background = element_rect(fill = NA, colour = NA),
      strip.text.x = element_text(colour = "white"),
      strip.text.y = element_text(colour = "white"),
      axis.text = element_text(colour = "white"),
      axis.title = element_text(colour = "white"),
      legend.title = element_text(colour = "white", size = rel(0.9)),
      panel.border = element_rect(fill = NA, colour = "grey70", linewidth = 1),
      legend.key.size = unit(0.9, "lines"),
      legend.text = element_text(size = rel(0.7), colour = "white"),
      legend.key = element_rect(colour = NA, fill = NA),
      legend.background = element_rect(colour = NA, fill = NA),
      plot.title = element_text(colour = "white", size = rel(1)),
      plot.subtitle = element_text(colour = "white", size = rel(.85)),
      
      # Parameters for a transparent plot.
      # In ggsave, also need to make bg = "transparent"
      panel.background = element_rect(fill = "transparent"),
      plot.background = element_rect(fill = "transparent", color = NA)
    )
}

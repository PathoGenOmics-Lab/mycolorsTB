#' Mycolors Color Palette
#'
#' A palette of colors designed for visually appealing plots. The `mycolors` palette
#' includes a range of colors suitable for a variety of plotting needs. With lineages names.
#'
#' @name mycolors
#' @export
mycolors <- c("A1"="#d1ae00", "A2"="#8ef5c8", "A3"="#73c2ff", "A4"="#ff9cdb",
              "L1"="#ff3091", "L2"="#001aff", "L3"="#8a0bd2", "L4"="#ff0000",
              "L5"="#995200", "L6"="#1eb040", "L7"="#fbff00", "L8"="#ff9d00",
              "L9"="#37ff30", "L10"="#8fbda1")

#' ClassicTB Color Palette
#'
#' This palette provides a set of colors derived from the `classicTB` theme,
#' suitable for creating distinctive and attractive visualizations.Without lineages names.
#'
#' @name classicTB
#' @export
classicTB <- c("#d1ae00", "#8ef5c8", "#73c2ff", "#ff9cdb",
               "#ff3091", "#001aff", "#8a0bd2", "#ff0000",
               "#995200", "#1eb040", "#fbff00", "#ff9d00",
               "#37ff30","#8fbda1")

#' Scale Color for ggplot2 Using mycolors Palette
#'
#' This function provides a color scale for ggplot2 plots, using the custom mycolors palette.
#'
#' @import ggplot2
#' @export
scale_color_mycolors <- function() {
  ggplot2::scale_colour_manual(values = mycolors)
}

#' Scale Fill for ggplot2 Using mycolors Palette
#'
#' This function provides a fill scale for ggplot2 plots, using the custom mycolors palette.
#'
#' @import ggplot2
#' @export
scale_fill_mycolors <- function() {
  ggplot2::scale_fill_manual(values = mycolors)
}

#' Scale Color for ggplot2 Using mycolors Palette
#'
#' This function provides a color scale for ggplot2 plots, using the custom classicTB palette.
#'
#' @import ggplot2
#' @export
scale_color_classicTB <- function() {
  ggplot2::scale_colour_manual(values = classicTB)
}

#' Scale Fill for ggplot2 Using mycolors Palette
#'
#' This function provides a fill scale for ggplot2 plots, using the custom classicTB palette.
#'
#' @import ggplot2
#' @export
scale_fill_classicTB <- function() {
  ggplot2::scale_fill_manual(values = classicTB)
}

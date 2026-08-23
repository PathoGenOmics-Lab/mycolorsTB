#' Mycolors Color Palette
#'
#' A named vector of 14 colors designed for visualizing Mycobacterium tuberculosis lineages.
#'
#' @format A character vector of 14 hex color codes, named with lineage identifiers.
#' @source Color palette designed by the PathoGenOmics Lab.
#' @export
mycolors <- c("A1"="#d1ae00", "A2"="#8ef5c8", "A3"="#73c2ff", "A4"="#ff9cdb",
              "L1"="#ff3091", "L2"="#001aff", "L3"="#8a0bd2", "L4"="#ff0000",
              "L5"="#995200", "L6"="#1eb040", "L7"="#fbff00", "L8"="#ff9d00",
              "L9"="#37ff30", "L10"="#8fbda1")

#' ClassicTB Color Palette
#'
#' The same 14 colors as [mycolors], but without lineage names, so that they can
#' be applied positionally to any categorical variable.
#'
#' @format A character vector of 14 hex color codes.
#' @source Color palette designed by the PathoGenOmics Lab.
#' @export
classicTB <- c("#d1ae00", "#8ef5c8", "#73c2ff", "#ff9cdb",
               "#ff3091", "#001aff", "#8a0bd2", "#ff0000",
               "#995200", "#1eb040", "#fbff00", "#ff9d00",
               "#37ff30","#8fbda1")

#' PathoGenOmics Color Palette
#'
#' A palette of 8 colors from the PathoGenOmics Lab theme.
#'
#' @format A character vector of 8 hex color codes.
#' @source Color palette designed by the PathoGenOmics Lab.
#' @export
pathogenomics <- c("#c01718","#305595","#3c5824","#d9d0ca","#9ec4e8","#c0b3a7","#fdf2f8","#020203")

# Validate a palette name and return it in its canonical form. Keeping this in
# one place stops a non-character argument from reaching switch(), which would
# otherwise select a palette by position instead of by name.
match_tb_palette <- function(palette_name) {
  choices <- c("mycolors", "classicTB", "pathogenomics")
  if (!is.character(palette_name) || length(palette_name) != 1L || is.na(palette_name)) {
    stop("`palette_name` must be a single palette name, one of: ",
         paste(choices, collapse = ", "), ".", call. = FALSE)
  }
  match.arg(palette_name, choices)
}

# Look up the colors of an already validated palette name.
tb_palette_values <- function(palette_name) {
  switch(palette_name,
         "mycolors" = mycolors,
         "classicTB" = classicTB,
         "pathogenomics" = pathogenomics)
}

# Pick black or white text for each swatch, whichever stays readable. Uses the
# WCAG relative luminance of the background color.
contrast_text_color <- function(colors) {
  channels <- grDevices::col2rgb(colors) / 255
  linear <- ifelse(channels <= 0.03928, channels / 12.92, ((channels + 0.055) / 1.055)^2.4)
  luminance <- 0.2126 * linear[1, ] + 0.7152 * linear[2, ] + 0.0722 * linear[3, ]
  ifelse(luminance > 0.179, "black", "white")
}

# Parse a Newick string, refusing anything that is not a single tree. Without
# this, ape::read.tree() returns NULL for malformed input and the failure only
# surfaces later as an empty plot.
read_tb_tree <- function(newick_text) {
  if (!is.character(newick_text) || length(newick_text) != 1L || is.na(newick_text)) {
    stop("`newick_text` must be a single character string in Newick format.", call. = FALSE)
  }
  tree <- ape::read.tree(text = newick_text)
  if (!inherits(tree, "phylo")) {
    stop("`newick_text` could not be parsed as a single tree in Newick format.", call. = FALSE)
  }
  tree
}

# Widen the horizontal axis to leave room for the tip labels, leaving the plot
# untouched when the tree has no usable horizontal extent.
expand_tree_xlim <- function(p, factor) {
  xmax <- suppressWarnings(max(p$data$x, na.rm = TRUE))
  if (!is.finite(xmax) || xmax <= 0) {
    return(p)
  }
  p + ggplot2::xlim(NA, xmax * factor)
}

#' Scale Color for ggplot2 Using mycolors Palette
#' @description Applies the `mycolors` palette to the color aesthetic in a ggplot.
#' @param ... Additional arguments passed to [ggplot2::scale_colour_manual()],
#'   such as `name`, `labels` or `na.value`.
#' @import ggplot2
#' @export
#' @return A ggplot2 scale object.
#' @examples
#' library(ggplot2)
#' df <- data.frame(x = names(mycolors), y = 1, lineage = names(mycolors))
#' ggplot(df, aes(x, y, color = lineage)) +
#'   geom_point(size = 4) +
#'   scale_color_mycolors(name = "Lineage")
scale_color_mycolors <- function(...) {
  ggplot2::scale_colour_manual(values = mycolors, ...)
}

#' Scale Fill for ggplot2 Using mycolors Palette
#' @description Applies the `mycolors` palette to the fill aesthetic in a ggplot.
#' @param ... Additional arguments passed to [ggplot2::scale_fill_manual()],
#'   such as `name`, `labels` or `na.value`.
#' @import ggplot2
#' @export
#' @return A ggplot2 scale object.
#' @examples
#' library(ggplot2)
#' df <- data.frame(x = names(mycolors), y = 1, lineage = names(mycolors))
#' ggplot(df, aes(x, y, fill = lineage)) +
#'   geom_col() +
#'   scale_fill_mycolors(name = "Lineage")
scale_fill_mycolors <- function(...) {
  ggplot2::scale_fill_manual(values = mycolors, ...)
}

#' Scale Color for ggplot2 Using classicTB Palette
#' @description Applies the `classicTB` palette to the color aesthetic in a ggplot.
#' @param ... Additional arguments passed to [ggplot2::scale_colour_manual()],
#'   such as `name`, `labels` or `na.value`.
#' @import ggplot2
#' @export
#' @return A ggplot2 scale object.
#' @examples
#' library(ggplot2)
#' df <- data.frame(x = letters[1:5], y = 1, group = letters[1:5])
#' ggplot(df, aes(x, y, color = group)) +
#'   geom_point(size = 4) +
#'   scale_color_classicTB()
scale_color_classicTB <- function(...) {
  ggplot2::scale_colour_manual(values = classicTB, ...)
}

#' Scale Fill for ggplot2 Using classicTB Palette
#' @description Applies the `classicTB` palette to the fill aesthetic in a ggplot.
#' @param ... Additional arguments passed to [ggplot2::scale_fill_manual()],
#'   such as `name`, `labels` or `na.value`.
#' @import ggplot2
#' @export
#' @return A ggplot2 scale object.
#' @examples
#' library(ggplot2)
#' df <- data.frame(x = letters[1:5], y = 1, group = letters[1:5])
#' ggplot(df, aes(x, y, fill = group)) +
#'   geom_col() +
#'   scale_fill_classicTB()
scale_fill_classicTB <- function(...) {
  ggplot2::scale_fill_manual(values = classicTB, ...)
}

#' Display a color palette
#' @description Generates a ggplot visualization of a specified package palette.
#'   Each hex code is written in black or white, whichever remains readable on
#'   top of its own swatch.
#' @param palette_name The name of the palette to display ("mycolors", "classicTB", or "pathogenomics").
#' @return A ggplot object showing the colors of the chosen palette.
#' @export
#' @importFrom grDevices col2rgb
#' @examples
#' view_palette("mycolors")
#' view_palette("classicTB")
view_palette <- function(palette_name = "mycolors") {
  palette_name <- match_tb_palette(palette_name)
  palette_data <- tb_palette_values(palette_name)

  if (is.null(names(palette_data))) {
    palette_labels <- as.character(palette_data)
  } else {
    palette_labels <- names(palette_data)
  }

  palette_df <- data.frame(
    name = factor(palette_labels, levels = palette_labels),
    hex = as.character(palette_data),
    text_color = contrast_text_color(palette_data),
    stringsAsFactors = FALSE
  )

  ggplot2::ggplot(palette_df, ggplot2::aes(x = .data$name, y = 1, fill = .data$name)) +
    ggplot2::geom_tile(color = "white", linewidth = 1) +
    ggplot2::geom_text(ggplot2::aes(label = .data$hex, color = .data$text_color),
                       vjust = 0.5, size = 3) +
    ggplot2::scale_fill_manual(values = palette_data, name = "") +
    ggplot2::scale_color_identity() +
    ggplot2::theme_minimal() +
    ggplot2::labs(title = paste("Palette:", palette_name), x = "", y = "") +
    ggplot2::theme(
      axis.text.y = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      legend.position = "none",
      panel.grid = ggplot2::element_blank()
    )
}


#' Plot a Phylogenetic Tree with TB Lineage Colors
#' @description Reads a tree in Newick format and plots it using ggtree, coloring tips with the `mycolors` palette.
#' @param newick_text A character string with the tree in Newick format.
#' @return A ggplot object representing the phylogenetic tree.
#' @export
#' @importFrom ape read.tree
#' @import ggtree
#' @examples
#' \dontrun{
#' tree_text <- "(L8,((L1,(L7,(L4,(L2,L3)))),(L5,((A2,(A3,A4)),(A1,(L10,(L6,L9)))))));"
#' plot_tb_tree(tree_text)
#' }
plot_tb_tree <- function(newick_text) {
  tree <- read_tb_tree(newick_text)
  p <- ggtree::ggtree(tree, ladderize = TRUE) +
    ggtree::geom_tippoint(ggplot2::aes(color = .data$label), size = 3) +
    ggtree::geom_tiplab(ggplot2::aes(color = .data$label), align = TRUE, size = 4) +
    scale_color_mycolors() +
    ggplot2::theme(legend.position = "none")
  expand_tree_xlim(p, 1.25)
}

#' Plot a Phylogenetic Cladogram with TB Lineage Colors
#' @description Visualizes a phylogenetic tree as a cladogram, coloring tips with the `mycolors` palette.
#' @param newick_text A character string with the tree in Newick format.
#' @return A ggplot object representing the phylogenetic cladogram.
#' @export
#' @importFrom ape read.tree
#' @import ggtree
#' @examples
#' \dontrun{
#' tree_text <- "(L8,((L1,(L7,(L4,(L2,L3)))),(L5,((A2,(A3,A4)),(A1,(L10,(L6,L9)))))));"
#' plot_tb_cladogram(tree_text)
#' }
plot_tb_cladogram <- function(newick_text) {
  tree <- read_tb_tree(newick_text)
  p <- ggtree::ggtree(tree, branch.length = 'none', ladderize = TRUE) +
    ggtree::geom_tippoint(ggplot2::aes(color = .data$label), size = 3) +
    ggtree::geom_tiplab(ggplot2::aes(color = .data$label), align = TRUE, size = 4) +
    scale_color_mycolors() +
    ggplot2::theme(legend.position = "none") +
    ggplot2::labs(title = "TB Lineage Cladogram")
  expand_tree_xlim(p, 1.5)
}

#' Generate n colors from a mycolorsTB palette
#' @description Returns `n` colors from a package palette. The palette colors are
#'   returned unchanged while `n` does not exceed the palette size, and are
#'   interpolated only when more colors than the palette holds are requested.
#' @param n The number of colors to generate. A single non-negative whole number.
#' @param palette_name The name of the palette to use ("mycolors", "classicTB", or "pathogenomics").
#' @return A character vector of n hex color codes.
#' @export
#' @importFrom grDevices colorRampPalette
#' @examples
#' # The first 5 colors of the palette, unchanged
#' tb_palette(5, "classicTB")
#'
#' # Generate 20 colors from the 'classicTB' palette
#' my_custom_colors <- tb_palette(20, "classicTB")
#' plot(1:20, 1:20, col = my_custom_colors, pch = 19, cex = 3)
tb_palette <- function(n, palette_name = "classicTB") {
  palette_name <- match_tb_palette(palette_name)
  pal <- tb_palette_values(palette_name)

  if (!is.numeric(n) || length(n) != 1L || is.na(n) || !is.finite(n) ||
      n < 0 || n != round(n)) {
    stop("`n` must be a single non-negative whole number.", call. = FALSE)
  }
  n <- as.integer(n)

  if (n <= length(pal)) {
    return(unname(pal[seq_len(n)]))
  }

  warning("Number of requested colors (", n, ") is greater than the size of the '",
          palette_name, "' palette (", length(pal), "). Colors are interpolated.",
          call. = FALSE)
  grDevices::colorRampPalette(pal)(n)
}

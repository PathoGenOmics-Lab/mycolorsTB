# This line prevents NOTES about non-standard evaluation in ggplot2
utils::globalVariables(c("label", "hex", "name"))

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
#' An unnamed vector of 14 colors derived from the `classicTB` theme.
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

#' Scale Color for ggplot2 Using mycolors Palette
#' @description Applies the `mycolors` palette to the color aesthetic in a ggplot.
#' @import ggplot2
#' @export
#' @return A ggplot2 scale object.
scale_color_mycolors <- function() {
  ggplot2::scale_colour_manual(values = mycolors)
}

#' Scale Fill for ggplot2 Using mycolors Palette
#' @description Applies the `mycolors` palette to the fill aesthetic in a ggplot.
#' @import ggplot2
#' @export
#' @return A ggplot2 scale object.
scale_fill_mycolors <- function() {
  ggplot2::scale_fill_manual(values = mycolors)
}

#' Scale Color for ggplot2 Using classicTB Palette
#' @description Applies the `classicTB` palette to the color aesthetic in a ggplot.
#' @import ggplot2
#' @export
#' @return A ggplot2 scale object.
scale_color_classicTB <- function() {
  ggplot2::scale_colour_manual(values = classicTB)
}

#' Scale Fill for ggplot2 Using classicTB Palette
#' @description Applies the `classicTB` palette to the fill aesthetic in a ggplot.
#' @import ggplot2
#' @export
#' @return A ggplot2 scale object.
scale_fill_classicTB <- function() {
  ggplot2::scale_fill_manual(values = classicTB)
}

#' Display a color palette
#' @description Generates a ggplot visualization of a specified package palette.
#' @param palette_name The name of the palette to display ("mycolors", "classicTB", or "pathogenomics").
#' @return A ggplot object showing the colors of the chosen palette.
#' @export
#' @examples
#' view_palette("mycolors")
#' view_palette("classicTB")
view_palette <- function(palette_name = "mycolors") {
  palette_data <- switch(palette_name,
                         "mycolors" = mycolors,
                         "classicTB" = classicTB,
                         "pathogenomics" = pathogenomics,
                         stop("Palette not found!"))

  if (is.null(names(palette_data))) {
    palette_names <- as.character(palette_data)
  } else {
    palette_names <- names(palette_data)
  }

  palette_df <- data.frame(
    name = factor(palette_names, levels = palette_names),
    hex = as.character(palette_data),
    stringsAsFactors = FALSE
  )

  ggplot2::ggplot(palette_df, ggplot2::aes(x = .data$name, y = 1, fill = .data$name)) +
    ggplot2::geom_tile(color = "white", size = 1) +
    ggplot2::geom_text(ggplot2::aes(label = .data$hex), vjust = 0.5, color = "black", size = 3) +
    ggplot2::scale_fill_manual(values = palette_data, name = "") +
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
  tree <- ape::read.tree(text = newick_text)
  p <- ggtree::ggtree(tree, ladderize = TRUE) +
    ggtree::geom_tippoint(ggplot2::aes(color = .data$label), size = 3) +
    ggtree::geom_tiplab(ggplot2::aes(color = .data$label), align = TRUE, size = 4) +
    scale_color_mycolors() +
    ggplot2::theme(legend.position = "none")
  p <- p + ggplot2::xlim(NA, max(p$data$x) * 1.25)
  return(p)
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
  tree <- ape::read.tree(text = newick_text)
  p <- ggtree::ggtree(tree, branch.length = 'none', ladderize = TRUE) +
    ggtree::geom_tippoint(ggplot2::aes(color = .data$label), size = 3) +
    ggtree::geom_tiplab(ggplot2::aes(color = .data$label), align = TRUE, size = 4) +
    scale_color_mycolors() +
    ggplot2::theme(legend.position = "none") +
    ggplot2::labs(title = "TB Lineage Cladogram")
  p <- p + ggplot2::xlim(NA, max(p$data$x) * 1.5)
  return(p)
}

#' Generate n colors from a mycolorsTB palette
#' @description Uses color interpolation to create a custom number of colors from a given palette.
#' @param n The number of colors to generate.
#' @param palette_name The name of the palette to use ("mycolors", "classicTB", or "pathogenomics").
#' @return A character vector of n hex color codes.
#' @export
#' @importFrom grDevices colorRampPalette
#' @examples
#' # Generate 20 colors from the 'classicTB' palette
#' my_custom_colors <- tb_palette(20, "classicTB")
#' plot(1:20, 1:20, col = my_custom_colors, pch = 19, cex = 3)
tb_palette <- function(n, palette_name = "classicTB") {
  pal <- switch(palette_name,
                "mycolors" = mycolors,
                "classicTB" = classicTB,
                "pathogenomics" = pathogenomics,
                stop("Palette not found!"))
  if (n > length(pal)) {
    warning("Number of requested colors is greater than the palette size. Colors are interpolated.")
  }
  color_func <- grDevices::colorRampPalette(pal)
  return(color_func(n))
}

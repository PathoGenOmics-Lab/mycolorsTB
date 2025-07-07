#' Mycolors Color Palette
#'
#' A palette of colors designed for visually appealing plots, including names for Mycobacterium tuberculosis lineages.
#' @export
mycolors <- c("A1"="#d1ae00", "A2"="#8ef5c8", "A3"="#73c2ff", "A4"="#ff9cdb",
              "L1"="#ff3091", "L2"="#001aff", "L3"="#8a0bd2", "L4"="#ff0000",
              "L5"="#995200", "L6"="#1eb040", "L7"="#fbff00", "L8"="#ff9d00",
              "L9"="#37ff30", "L10"="#8fbda1")

#' ClassicTB Color Palette
#'
#' A palette of colors derived from the `classicTB` theme, without lineage names.
#' @export
classicTB <- c("#d1ae00", "#8ef5c8", "#73c2ff", "#ff9cdb",
               "#ff3091", "#001aff", "#8a0bd2", "#ff0000",
               "#995200", "#1eb040", "#fbff00", "#ff9d00",
               "#37ff30","#8fbda1")

#' PathoGenOmics Color Palette
#'
#' A palette of colors from the PathoGenOmics Lab theme.
#' @export
pathogenomics <- c("#c01718","#305595","#3c5824","#d9d0ca","#9ec4e8","#c0b3a7","#fdf2f8","#020203")

#' Scale Color for ggplot2 Using mycolors Palette
#'
#' @import ggplot2
#' @export
#' @return A ggplot2 scale object.
scale_color_mycolors <- function() {
  ggplot2::scale_colour_manual(values = mycolors)
}

#' Scale Fill for ggplot2 Using mycolors Palette
#'
#' @import ggplot2
#' @export
#' @return A ggplot2 scale object.
scale_fill_mycolors <- function() {
  ggplot2::scale_fill_manual(values = mycolors)
}

#' Scale Color for ggplot2 Using classicTB Palette
#'
#' @import ggplot2
#' @export
#' @return A ggplot2 scale object.
scale_color_classicTB <- function() {
  ggplot2::scale_colour_manual(values = classicTB)
}

#' Scale Fill for ggplot2 Using classicTB Palette
#'
#' @import ggplot2
#' @export
#' @return A ggplot2 scale object.
scale_fill_classicTB <- function() {
  ggplot2::scale_fill_manual(values = classicTB)
}

#' Display a color palette
#'
#' This function now correctly handles palettes with or without names.
#'
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

  # Handle palettes with and without names to avoid errors
  if (is.null(names(palette_data))) {
    palette_names <- as.character(palette_data)
  } else {
    palette_names <- names(palette_data)
  }

  palette_df <- data.frame(
    name = factor(palette_names, levels = palette_names), # Preserve order
    hex = as.character(palette_data),
    stringsAsFactors = FALSE
  )

  ggplot2::ggplot(palette_df, ggplot2::aes(x = name, y = 1, fill = name)) +
    ggplot2::geom_tile(color = "white", size = 1) +
    ggplot2::geom_text(ggplot2::aes(label = hex), vjust = 0.5, color = "black", size = 3) +
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
#'
#' This function has been improved to be more robust and create a cleaner plot.
#'
#' @param newick_text A character string with the tree in Newick format.
#' @return A ggplot object representing the phylogenetic tree.
#' @export
#' @import ape
#' @import ggtree
#' @examples
#' \dontrun{
#' tree_text <- "(L8,((L1,(L7,(L4,(L2,L3)))),(L5,((A2,(A3,A4)),(A1,(L10,(L6,L9)))))));"
#' plot_tb_tree(tree_text)
#' }
plot_tb_tree <- function(newick_text) {
  # Read the tree from the text string
  tree <- ape::read.tree(text = newick_text)

  # Plot the tree using ggtree
  p <- ggtree::ggtree(tree, ladderize = TRUE) + # ladderize for a cleaner look
    # Add points at the tips of the tree, colored by their label
    ggtree::geom_tippoint(ggplot2::aes(color = label), size = 3) +
    # Add text labels for the tips, also colored by their label
    ggtree::geom_tiplab(ggplot2::aes(color = label), align = TRUE, size = 4) +
    # Apply the custom color scale from this package
    scale_color_mycolors() +
    # Remove the legend since the labels are colored directly
    ggplot2::theme(legend.position = "none")

  # Dynamically expand the x-axis to make space for labels
  p <- p + ggplot2::xlim(NA, max(p$data$x) * 1.25)

  return(p)
}

#' Plot a Phylogenetic Cladogram with TB Lineage Colors
#'
#' This function visualizes a phylogenetic tree as a cladogram (ignoring branch lengths)
#' and colors the tips according to the `mycolors` palette.
#'
#' @param newick_text A character string with the tree in Newick format.
#' @return A ggplot object representing the phylogenetic cladogram.
#' @export
#' @import ape
#' @import ggtree
#' @examples
#' \dontrun{
#' tree_text <- "(L8,((L1,(L7,(L4,(L2,L3)))),(L5,((A2,(A3,A4)),(A1,(L10,(L6,L9)))))));"
#' plot_tb_cladogram(tree_text)
#' }
plot_tb_cladogram <- function(newick_text) {
  # Read the tree from the text string
  tree <- ape::read.tree(text = newick_text)

  # Plot the tree as a cladogram, where branch lengths are ignored
  p <- ggtree::ggtree(tree, branch.length = 'none', ladderize = TRUE) +
    ggtree::geom_tippoint(ggplot2::aes(color = label), size = 3) +
    ggtree::geom_tiplab(ggplot2::aes(color = label), align = TRUE, size = 4) +
    scale_color_mycolors() +
    ggplot2::theme(legend.position = "none") +
    ggplot2::labs(title = "TB Lineage Cladogram")

  # Dynamically expand the x-axis to make space for labels
  p <- p + ggplot2::xlim(NA, max(p$data$x) * 1.5)

  return(p)
}

#' Generate n colors from a mycolorsTB palette
#'
#' Uses color interpolation to create a custom number of colors from a given palette.
#' This is useful when you need more colors than are available in the base palette.
#'
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

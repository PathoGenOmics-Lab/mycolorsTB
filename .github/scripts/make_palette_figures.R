#!/usr/bin/env Rscript

# make_palette_figures.R
#
# Renders the figures the documentation site shows on its Home and Palettes
# pages. Each figure is written twice, once for the light theme and once for the
# dark one:
#
#   docs/assets/quickstart.png            docs/assets/quickstart-dark.png
#   docs/assets/palette-mycolors.png      docs/assets/palette-mycolors-dark.png
#   docs/assets/palette-pathogenomics.png docs/assets/palette-pathogenomics-dark.png
#   docs/assets/scale-by-name.png         docs/assets/scale-by-name-dark.png
#   docs/assets/cvd-deuteranopia.png      docs/assets/cvd-deuteranopia-dark.png
#
# Two variants and not one, for the same reason images/example1_dark.png exists:
# every one of these figures carries text on a transparent ground, and a single
# render fixes that text to one canvas. Material for MkDocs serves both themes
# from the same page, and picks between the two files with the `#only-light` and
# `#only-dark` fragments the Markdown appends to the image path.
#
# Only non-data elements differ between the two variants: axis text, titles,
# grid lines. Every swatch, bar and tile border keeps the colour the package
# gives it, because the palette is the subject of every figure here. The white
# borders view_palette() draws between swatches are part of what the function
# produces, so they are left alone rather than restyled per theme.
#
# Usage:
#   Rscript .github/scripts/make_palette_figures.R [output_directory]
#
# Requires: mycolorsTB, ragg, and, for the colour vision figure only,
# colorspace (>= 2.1). DESCRIPTION asks for neither: they are what this
# development script needs, not what the package needs, exactly as its sibling
# make_example_plots.R needs ragg and ggplot2 (>= 3.5.0).

# Resolved the same way the sibling resolves it, so the script rebuilds the
# committed assets from any working directory.
this_file <- sub("^--file=", "",
                 grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[1L])
script_dir <- dirname(normalizePath(this_file))
repo_root <- dirname(dirname(script_dir))

# make_example_plots.R only renders when it is executed, so sourcing it here
# brings in library(mycolorsTB), library(ggplot2) and strip_bkgd() without
# writing anything. The PNG chunk surgery that strip_bkgd() performs is subtle
# enough that a second copy of it would be a second thing to keep correct.
source(file.path(script_dir, "make_example_plots.R"))
suppressPackageStartupMessages(library(colorspace))

RENDER_RES <- 300L

# Non-data colours, measured rather than chosen by eye.
#
# Light is ggplot2's own theme_minimal() palette, which is what a reader gets
# from running the snippets unchanged: grey30 axis text is 8.45:1 on white,
# black titles 21:1, grey92 grid lines 1.19:1.
#
# Dark is measured against #1e2129, which is the background Material for MkDocs
# paints under the `slate` scheme this site uses: hsl(225, 15%, 14%), from
# Material's own --md-hue and --md-default-bg-color.
#   #b9bdc9 axis text    8.57:1, next to grey30's 8.45:1 on white
#   #e6e9f0 titles      13.24:1
#   #3a3d47 grid lines   1.49:1, the same faint band grey92 sits in on white
# The grid has to separate the bars without competing with fourteen saturated
# fills, so matching the light variant's ratio matters more than matching its
# lightness.
THEMES <- list(
  light = list(
    suffix = "",
    axis_text = "grey30",
    title_text = "black",
    grid = "grey92"
  ),
  dark = list(
    suffix = "-dark",
    axis_text = "#b9bdc9",
    title_text = "#e6e9f0",
    grid = "#3a3d47"
  )
)

# Every figure is transparent end to end. theme_minimal() fills plot.background
# with white, which would otherwise punch a white rectangle through the dark
# page.
theme_for <- function(variant, grid = TRUE) {
  ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = NA, colour = NA),
    panel.background = ggplot2::element_rect(fill = NA, colour = NA),
    legend.background = ggplot2::element_rect(fill = NA, colour = NA),
    legend.key = ggplot2::element_rect(fill = NA, colour = NA),
    axis.text = ggplot2::element_text(colour = variant$axis_text),
    axis.title = ggplot2::element_text(colour = variant$title_text),
    plot.title = ggplot2::element_text(colour = variant$title_text),
    legend.text = ggplot2::element_text(colour = variant$title_text),
    legend.title = ggplot2::element_text(colour = variant$title_text),
    axis.ticks = ggplot2::element_blank(),
    panel.grid = if (grid) {
      ggplot2::element_line(colour = variant$grid)
    } else {
      ggplot2::element_blank()
    }
  )
}

render <- function(plot, out_dir, stem, variant, width_px, height_px) {
  path <- file.path(out_dir, paste0(stem, variant$suffix, ".png"))
  ragg::agg_png(filename = path, width = width_px, height = height_px,
                units = "px", res = RENDER_RES, background = "transparent")
  on.exit(grDevices::dev.off(), add = TRUE)
  print(plot)
  # ragg writes a bKGD chunk naming black as the suggested background. Anything
  # that honours it while flattening the alpha channel would composite the light
  # variant's grey30 axis text onto black. See make_example_plots.R.
  on.exit(strip_bkgd(path), add = TRUE)
  message("wrote ", path)
  invisible(path)
}

# --- The figures ------------------------------------------------------------

# Home page. The counts are the ones written out in the Home page snippet, so a
# reader who runs it plots these bars. Fourteen legend entries do not fit at the
# default key size, and the overflow silently clips the legend title away, hence
# the same key tightening make_example_plots.R applies.
quickstart_data <- data.frame(
  lineage = factor(names(mycolorsTB::mycolors), levels = names(mycolorsTB::mycolors)),
  isolates = c(3, 5, 4, 2, 41, 58, 22, 96, 13, 74, 6, 9, 4, 2)
)

quickstart_plot <- function(variant) {
  ggplot2::ggplot(quickstart_data,
                  ggplot2::aes(x = .data$lineage, y = .data$isolates, fill = .data$lineage)) +
    ggplot2::geom_col() +
    mycolorsTB::scale_fill_mycolors(name = "Lineage") +
    ggplot2::labs(x = NULL, y = "Isolates") +
    ggplot2::theme_minimal(base_size = 11) +
    theme_for(variant) +
    ggplot2::theme(
      legend.key.size = ggplot2::unit(1, "lines"),
      legend.key.spacing.y = ggplot2::unit(0, "pt")
    )
}

# Palettes page, swatch figures. view_palette() is called exactly as the page
# documents it; the theme_for() layer only recolours the title and the tick
# labels, which are the two pieces of text the function puts outside the
# swatches. The hex codes inside them are already black or white by luminance,
# so they need nothing from either theme.
palette_plot <- function(palette_name, variant) {
  mycolorsTB::view_palette(palette_name) + theme_for(variant, grid = FALSE)
}

# Palettes page, name matching. The fifth category is not a name in mycolors, so
# it takes na.value instead of a lineage colour. That is the whole point of the
# figure: nothing fails, one bar just comes out grey.
by_name_data <- data.frame(
  lineage = c("L1", "L2", "L4", "A1", "L11"),
  isolates = c(41, 58, 96, 3, 7)
)

by_name_plot <- function(variant) {
  ggplot2::ggplot(by_name_data,
                  ggplot2::aes(x = .data$lineage, y = .data$isolates, fill = .data$lineage)) +
    ggplot2::geom_col() +
    mycolorsTB::scale_fill_mycolors(name = "Lineage", na.value = "grey70") +
    ggplot2::labs(x = NULL, y = "Isolates") +
    ggplot2::theme_minimal(base_size = 11) +
    theme_for(variant)
}

# Palettes page, colour vision. The lower row is mycolors as the package ships
# it; the upper row is the same fourteen colours passed through
# colorspace::deutan(), which applies the Machado, Oliveira and Fernandes (2009)
# simulation of deuteranopia. Nothing here is a claim about the palette beyond
# what that simulation returns, and the Palettes page quotes the CIEDE2000
# distances that go with it.
cvd_data <- local({
  nm <- names(mycolorsTB::mycolors)
  rbind(
    data.frame(row = "Deuteranopia, simulated", name = nm,
               hex = colorspace::deutan(unname(mycolorsTB::mycolors))),
    data.frame(row = "As shipped", name = nm, hex = unname(mycolorsTB::mycolors))
  )
})
cvd_data$row <- factor(cvd_data$row, levels = c("As shipped", "Deuteranopia, simulated"))
cvd_data$name <- factor(cvd_data$name, levels = names(mycolorsTB::mycolors))

cvd_plot <- function(variant) {
  ggplot2::ggplot(cvd_data,
                  ggplot2::aes(x = .data$name, y = .data$row, fill = .data$hex)) +
    ggplot2::geom_tile(colour = "white", linewidth = 1) +
    ggplot2::scale_fill_identity() +
    ggplot2::labs(x = NULL, y = NULL) +
    ggplot2::theme_minimal(base_size = 11) +
    theme_for(variant, grid = FALSE)
}

# Width, height and the builder for each figure. Heights are set by what has to
# fit: the Home chart carries a fourteen-entry legend, the swatch figures carry
# rotated tick labels under fourteen or eight tiles.
FIGURES <- list(
  list(stem = "quickstart", w = 1950L, h = 1200L, f = quickstart_plot),
  list(stem = "palette-mycolors", w = 2400L, h = 1000L,
       f = function(v) palette_plot("mycolors", v)),
  list(stem = "palette-pathogenomics", w = 2400L, h = 1000L,
       f = function(v) palette_plot("pathogenomics", v)),
  list(stem = "scale-by-name", w = 1800L, h = 1000L, f = by_name_plot),
  list(stem = "cvd-deuteranopia", w = 2400L, h = 800L, f = cvd_plot)
)

main <- function(out_dir) {
  if (!dir.exists(out_dir)) {
    stop("Output directory does not exist: ", out_dir, call. = FALSE)
  }
  for (fig in FIGURES) {
    for (variant in THEMES) {
      render(fig$f(variant), out_dir, fig$stem, variant, fig$w, fig$h)
    }
  }
  invisible(NULL)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  out_dir <- if (length(args) >= 1L) args[[1L]] else file.path(repo_root, "docs", "assets")
  main(out_dir)
}

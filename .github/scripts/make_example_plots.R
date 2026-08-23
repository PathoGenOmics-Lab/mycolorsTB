#!/usr/bin/env Rscript

# make_example_plots.R
#
# Produces the two README example charts:
#
#   images/example1.png       light variant, shown on GitHub's light canvas (#ffffff)
#   images/example1_dark.png  dark variant, shown on GitHub's dark canvases
#                             (#0d1117 default, #22272e dimmed, #010409 high contrast)
#
# Why this script exists:
#
#   1. The chart in README.md is built from rnorm(14). Without a seed the committed
#      image shows data that nobody can reproduce. The seed below is fixed and the
#      README example carries the same set.seed() call, so a reader who runs the
#      snippet plots the same 14 values the committed figure plots. The image
#      itself is not what the bare snippet renders: this script adds a transparent
#      background and the legend key tightening described below, both of which the
#      minimal snippet deliberately leaves out.
#   2. Both variants are rendered from that single seeded dataset in one run. If the
#      dark variant were generated separately it would show different bars, and a
#      reader switching GitHub themes would watch the data change under them.
#
# Only the non-data elements change between the variants: axis text, axis titles,
# legend text, legend title and grid lines. The bars keep the mycolors palette
# unchanged, because the palette is the subject of the figure. Both variants are
# rendered with a transparent background so each one sits directly on GitHub's own
# canvas instead of carrying a rectangle of the wrong colour.
#
# Usage:
#   Rscript .github/scripts/make_example_plots.R [output_directory]
#
# Requires: mycolorsTB, ragg, and ggplot2 (>= 3.5.0) for legend.key.spacing.y.
# DESCRIPTION only asks for ggplot2 (>= 3.4.0), which is the floor the package needs,
# not the floor this development script needs.

suppressPackageStartupMessages({
  library(mycolorsTB)
  library(ggplot2)
})

# Fixed seed. This value is duplicated in the README example chunk; keep them equal.
# It fixes the data, not the rendering.
EXAMPLE_SEED <- 42L

# Output geometry. The committed images are 1625 x 1057 px at 300 dpi, which is
# 5.42 x 3.52 inches. RENDER_BASE_SIZE is theme_minimal()'s own default, which is
# what the plain README snippet uses, so the text keeps the same apparent size it
# has in the historical image: an x-axis tick label measures 27 px cap height in
# both.
RENDER_WIDTH_PX <- 1625L
RENDER_HEIGHT_PX <- 1057L
RENDER_RES <- 300L
RENDER_BASE_SIZE <- 11

# Non-data colours.
#
# Light: ggplot2's own theme_minimal() defaults, so the light image keeps the tones a
# reader gets from the plain README snippet. grey30 axis text is 8.45:1 on #ffffff,
# black titles are 21:1, grey92 grid lines are 1.19:1. Sizing is the snippet's too;
# the only departure from it is the legend key tightening noted below.
#
# Dark: chosen by measuring WCAG contrast against #0d1117 rather than by eye.
#   #adbac7 axis text      9.58:1 on #0d1117, 7.60:1 on #22272e, 10.39:1 on #010409
#   #e6edf3 titles/legend 16.02:1 on #0d1117, 12.72:1 on #22272e, 17.38:1 on #010409
#   #30363d grid lines     1.55:1 on #0d1117,  1.23:1 on #22272e,  1.68:1 on #010409
# The grid sits in the same faint band as grey92 on white, so it separates the bars
# without competing with them on any of the three dark canvases.
VARIANTS <- list(
  light = list(
    file = "example1.png",
    axis_text = "grey30",
    title_text = "black",
    grid = "grey92"
  ),
  dark = list(
    file = "example1_dark.png",
    axis_text = "#adbac7",
    title_text = "#e6edf3",
    grid = "#30363d"
  )
)

# The seeded dataset, built once and shared by both variants.
example_data <- function(seed = EXAMPLE_SEED) {
  set.seed(seed)
  data.frame(
    x = 1:14,
    y = stats::rnorm(14),
    group = names(mycolorsTB::mycolors)
  )
}

# The chart the README documents, restyled for one canvas.
#
# theme_minimal() draws no axis ticks, so there are no tick marks to recolour; the
# element is left blank in both variants rather than switched on for the dark one,
# which would make the two images differ in more than colour.
example_plot <- function(data, variant) {
  ggplot(data, aes(x = .data$x, y = .data$y, fill = .data$group)) +
    geom_bar(stat = "identity") +
    scale_fill_mycolors() +
    theme_minimal(base_size = RENDER_BASE_SIZE) +
    theme(
      # Transparent everywhere. theme_minimal() fills plot.background with white,
      # which would defeat the transparent device background.
      plot.background = element_rect(fill = NA, colour = NA),
      panel.background = element_rect(fill = NA, colour = NA),
      legend.background = element_rect(fill = NA, colour = NA),
      legend.key = element_rect(fill = NA, colour = NA),
      axis.text = element_text(colour = variant$axis_text),
      axis.title = element_text(colour = variant$title_text),
      legend.text = element_text(colour = variant$title_text),
      legend.title = element_text(colour = variant$title_text),
      axis.ticks = element_blank(),
      panel.grid = element_line(colour = variant$grid),
      # Fourteen vertical legend entries do not fit in a 3.52 inch tall figure at
      # the default key size, and the overflow silently clips the legend title off
      # the top edge. Tightening the keys keeps every entry and the title visible.
      legend.key.size = unit(1, "lines"),
      legend.key.spacing.y = unit(0, "pt")
    )
}

# Drop one chunk from a PNG's chunk stream, leaving every other chunk, and so the
# pHYs resolution, exactly as written. The stream is: an 8 byte signature, then
# repeating (4 byte big-endian length, 4 byte type, data, 4 byte CRC).
strip_bkgd <- function(path) {
  raw_png <- readBin(path, "raw", n = file.size(path))
  out <- raw_png[1:8]
  i <- 9L
  while (i <= length(raw_png)) {
    len <- sum(as.integer(raw_png[i:(i + 3L)]) * c(256^3, 256^2, 256, 1))
    type <- rawToChar(raw_png[(i + 4L):(i + 7L)])
    total <- 12L + len
    if (type != "bKGD") {
      out <- c(out, raw_png[i:(i + total - 1L)])
    }
    i <- i + total
  }
  writeBin(out, path)
  invisible(path)
}

render_variant <- function(plot, path) {
  ragg::agg_png(
    filename = path,
    width = RENDER_WIDTH_PX,
    height = RENDER_HEIGHT_PX,
    units = "px",
    res = RENDER_RES,
    background = "transparent"
  )
  on.exit(grDevices::dev.off(), add = TRUE)
  print(plot)
  # ragg writes a bKGD chunk suggesting a black background, which the historical
  # image did not carry. Browsers and GitHub ignore it, but anything that honours
  # it while flattening the alpha channel composites the light variant's grey30
  # axis text and black titles onto black and produces an unreadable figure.
  on.exit(strip_bkgd(path), add = TRUE)
  invisible(path)
}

main <- function(out_dir) {
  if (!dir.exists(out_dir)) {
    stop("Output directory does not exist: ", out_dir, call. = FALSE)
  }
  data <- example_data()
  for (variant in VARIANTS) {
    path <- file.path(out_dir, variant$file)
    render_variant(example_plot(data, variant), path)
    message("wrote ", path)
  }
  invisible(NULL)
}

# Render only when the file is executed, so that it can also be sourced to reuse
# example_data() and example_plot() in a check.
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  # Resolved from this file rather than from the working directory, so the script
  # regenerates the committed assets from anywhere, the way its sibling
  # make_dark_logo.py does. Run from elsewhere with a relative default, it either
  # aborted or wrote the assets into an unrelated images/ that happened to exist.
  this_file <- sub("^--file=", "", grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)[1L])
  repo_root <- dirname(dirname(dirname(normalizePath(this_file))))
  out_dir <- if (length(args) >= 1L) args[[1L]] else file.path(repo_root, "images")
  main(out_dir)
}

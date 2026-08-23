# mycolorsTB 0.1.2

## Bug fixes

* `view_palette()` no longer triggers the ggplot2 deprecation warning about the
  `size` aesthetic for lines. The tile borders now use `linewidth`.

* `view_palette()` writes each hex code in black or white depending on the
  luminance of its own swatch. Previously the labels were always black, which
  made them unreadable on dark colours such as `#020203` in the
  `pathogenomics` palette.

* `tb_palette()` returns the palette colours unchanged while `n` does not exceed
  the palette size, and interpolates only when more colours are requested than
  the palette holds. Before this release every call interpolated, so
  `tb_palette(5, "mycolors")` returned five colours that matched no lineage,
  contradicting the warning the function itself emits.

* `tb_palette()` and `view_palette()` validate `palette_name`. A non-character
  value used to reach `switch()` and silently select a palette by position, so
  `tb_palette(3, 2)` quietly returned colours from a palette the caller never
  named.

* `tb_palette()` validates `n`. Negative, missing, infinite and fractional
  values used to fail with an internal message from `colorRampPalette()` or to
  round silently.

* `plot_tb_tree()` and `plot_tb_cladogram()` reject input that is not a single
  Newick tree. Malformed strings made `ape::read.tree()` return `NULL`, and the
  functions went on to build a plot with an empty axis range instead of
  reporting the problem.

## Improvements

* The four `scale_*_mycolors()` and `scale_*_classicTB()` functions accept `...`
  and pass it to the underlying ggplot2 scale, so arguments such as `name`,
  `labels` and `na.value` can now be set.

* `grDevices` is declared in `Imports`, and `ggplot2` carries the `>= 3.4.0`
  requirement implied by the use of `linewidth`.

* The `images/` directory is excluded from the build, which removes the
  `R CMD check` note about a non-standard top level directory and drops around
  490 KB from the source tarball. The README keeps rendering the images from
  GitHub.

# mycolorsTB 0.1.1

* First CRAN release.

# Troubleshooting

Every entry here is a failure someone has actually hit with this package or with
the packages it sits on. Nothing on this page is hypothetical.

## `could not find function "is.waive"` when a tree is drawn

Symptom: `plot_tb_tree()` or `plot_tb_cladogram()` returns without complaint,
and then printing or saving the result fails.

```text
Error in `geom_segment2()`:
! Problem while converting geom to grob.
i Error occurred in the 4th layer.
Caused by error in `is.waive()`:
! could not find function "is.waive"
```

Cause: an old ggtree meeting ggplot2 4.x. ggplot2 4.0 renamed the internal
helper `is.waive()` to `is_waiver()`, and ggtree's aligned tip labels still call
the old name. Both tree helpers use `geom_tiplab(align = TRUE)`, so both hit it.

This is not a mycolorsTB bug and mycolorsTB is not involved. It reproduces with
plain ggtree, in a session where this package was never loaded:

```r
library(ggtree)

tr <- ape::read.tree(text = "(A,(B,C));")

print(ggtree(tr) + geom_tiplab(align = TRUE))   # fails
print(ggtree(tr) + geom_tiplab(align = FALSE))  # renders
```

Fix: update ggtree. The versions that call the old name predate the ggplot2 4.0
rename, and ggtree ships from Bioconductor rather than CRAN, so
`update.packages()` will not reach it:

```r
BiocManager::install("ggtree")
```

Check what you have before and after:

```r
packageVersion("ggtree")
packageVersion("ggplot2")
```

The other half of the pairing is ggplot2 itself: the call worked for as long as
ggplot2 still provided `is.waive()`. Holding ggplot2 back is therefore also a
way out, but it is the wrong end of the problem to fix, and it pins you behind
the rest of the ecosystem.

## My bars came out grey

Symptom: a bar chart or a scatter plot where some categories carry palette
colours and the rest are grey, with no error, no warning, and no legend entry
for the grey ones.

Cause: `mycolors` is a **named** vector, and the four `*_mycolors()` scales
match by name. A value that is not one of `A1` to `A4` or `L1` to `L10` is
treated as missing and filled with `na.value`, whose default is `"grey50"`.
Nothing is reported, because from ggplot2's point of view nothing went wrong.

Confirm it in one line:

```r
counts <- data.frame(lineage = c("L2", "L4", "Beijing", "unknown"), n = c(112, 208, 40, 6))

setdiff(unique(counts$lineage), names(mycolors))
#> [1] "Beijing" "unknown"
```

`character(0)` means every value has a colour. Anything else is exactly the set
of values that came out grey. The usual culprits are sublineage codes (`L4.9`),
spoligotype family names (`Beijing`, `LAM`), lowercase (`l4`), leading spaces,
and placeholders such as `unknown`, `NA` and `-`.

Fixes, in order of preference:

1. Recode the column to the fourteen names the palette knows.
2. If some rows genuinely have no lineage, keep them but make the fallback
   deliberate: `scale_fill_mycolors(na.value = "grey20")` and say in the caption
   what it means. `na.value` became settable in 0.1.2.
3. If the variable is not lineages at all, use `scale_fill_classicTB()`, which
   colours by position and never leaves a level uncoloured, or build the mapping
   yourself with `scale_fill_manual()`.

The same trap applies to trees, where the tip labels are the values being
matched. See [Trees](trees.md#tip-labels-have-to-be-lineage-names).

## `Insufficient values in manual scale`

Symptom:

```text
Error in `palette()`:
! Insufficient values in manual scale. 18 needed but only 14 provided.
```

Cause: the `classicTB` scales carry 14 colours and `mycolors` carries 14 names.
A manual scale in ggplot2 needs one value per level and refuses to recycle. The
error arrives at draw time, so the plot object is built successfully and fails
when you print or save it.

Fix: generate as many colours as you have levels and pass them to a plain manual
scale.

```r
many <- data.frame(region = sprintf("R%02d", 1:18), n = seq(30, 200, length.out = 18))

k <- nlevels(factor(many$region))

ggplot(many, aes(x = region, y = n, fill = region)) +
  geom_col() +
  scale_fill_manual(values = tb_palette(k, "classicTB"), guide = "none")
```

`tb_palette()` will warn that it interpolated. Read the warning rather than
suppressing it: interpolated colours are not palette colours, and more than
fourteen categories is more than a reader can tell apart on any palette. Merging
the small categories into an "other" bucket usually makes a better figure than
eighteen shades.

## `install.packages()` did not get me ggtree

Symptom: loading mycolorsTB fails with

```text
there is no package called 'ggtree'
```

and `install.packages("ggtree")` does not fix it, warning instead that the
package is not available.

Cause: ggtree is a Bioconductor package, not a CRAN one, and
`install.packages()` only looks at the repositories configured for it, which by
default are CRAN's.
mycolorsTB declares ggtree in `Imports`, so the dependency is real and the load
fails without it.

Fix:

```r
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
BiocManager::install("ggtree")
```

Then install mycolorsTB as usual. Only `plot_tb_tree()` and
`plot_tb_cladogram()` need ggtree; the palettes and the four ggplot2 scales do
not, but R loads the whole namespace, so the package will not attach until
ggtree is present.

If `BiocManager::install()` reports that your Bioconductor release does not
match your R version, upgrade R first. Bioconductor pins a release to an R
version and will not install a package built for another one.

## The same script gives different colours than it used to

Three behaviours changed in 0.1.2, and all three change output rather than
raising an error, so a script that ran on 0.1.1 can run on 0.1.2 and give
something else. Check with `packageVersion("mycolorsTB")`.

### `tb_palette()` no longer interpolates below the palette size

On 0.1.1 every call went through `colorRampPalette()`, whatever `n` was. On
0.1.2 the palette colours are returned unchanged while `n` does not exceed the
palette size, and interpolation happens only above it.

```r
tb_palette(5, "mycolors")
#> [1] "#d1ae00" "#8ef5c8" "#73c2ff" "#ff9cdb" "#ff3091"
```

Those are now A1, A2, A3, A4 and L1. On 0.1.1 they were five points sampled
along a ramp through all fourteen, matching no lineage, while the function's own
warning said interpolation only happened when you asked for more colours than
the palette held.

If a figure has to keep the old colours, the old behaviour is one call:
`grDevices::colorRampPalette(mycolors)(5)`. In almost every other case the new
colours are the ones you meant.

Interpolated output is uppercase and palette colours are lowercase, which is a
quick way to tell which you are looking at.

### A number in `palette_name` is now an error

```r
tb_palette(3, 2)
#> Error: `palette_name` must be a single palette name, one of: mycolors, classicTB, pathogenomics.
```

On 0.1.1 that reached `switch()`, which selects by position when it is handed a
number, and returned colours from the second palette without saying so. The
argument order is `tb_palette(n, palette_name)`, so a lone palette name is also
caught now:

```r
tb_palette("classicTB")
#> Error: `n` must be a single non-negative whole number.
```

Negative, fractional, missing and infinite values of `n` are rejected the same
way, where before they either rounded silently or failed with an internal
message from `colorRampPalette()`.

### Malformed Newick is now an error

```r
plot_tb_tree("(L1,L2")
#> Error: `newick_text` could not be parsed as a single tree in Newick format.
```

On 0.1.1 `ape::read.tree()` returned `NULL` for this and the function carried
on, producing a plot with an empty axis range: a blank panel and no explanation.
Any pipeline that was quietly generating blank tree panels will now stop at the
tree that caused it.

## There is no `scale_fill_pathogenomics()`

Only `mycolors` and `classicTB` have scale functions. The `pathogenomics`
palette is exported as a plain vector and reached directly:

```r
df <- data.frame(group = c("cases", "controls", "unresolved"), y = c(64, 51, 12))

ggplot(df, aes(x = group, y = y, fill = group)) +
  geom_col() +
  scale_fill_manual(values = pathogenomics)
```

or through `tb_palette(n, "pathogenomics")` when you want a specific number of
colours. Bear in mind that it is a theme palette running from near-white to
near-black, so it is not eight mutually distinguishable categorical colours.

## Nothing here matches

Open an issue at
[PathoGenOmics-Lab/mycolorsTB](https://github.com/PathoGenOmics-Lab/mycolorsTB/issues)
with the output of `sessionInfo()` and the smallest script that reproduces the
problem. For anything that draws a tree, the versions of ggtree and ggplot2 are
usually the answer, so include them.

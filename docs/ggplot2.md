# Using with ggplot2

Four functions put a package palette on a ggplot:

| Function | Aesthetic | Palette | Colours are matched |
|---|---|---|---|
| `scale_color_mycolors()` | `colour` | `mycolors` | by lineage name |
| `scale_fill_mycolors()` | `fill` | `mycolors` | by lineage name |
| `scale_color_classicTB()` | `colour` | `classicTB` | by position |
| `scale_fill_classicTB()` | `fill` | `classicTB` | by position |

All four are thin wrappers. The `mycolors` pair calls
`ggplot2::scale_colour_manual()` and `ggplot2::scale_fill_manual()` with
`values = mycolors`, the `classicTB` pair calls the same two with
`values = classicTB`. Nothing else happens, which is worth knowing because it
tells you exactly what the scales can and cannot do: everything a manual scale
does, and nothing a manual scale does not.

Since 0.1.2 they take `...` and forward it, so `name`, `labels`, `breaks`,
`na.value`, `guide` and `drop` all reach the underlying scale. In 0.1.1 they
took no arguments at all, and the legend they produced was the legend you got.

## Colouring by lineage

`mycolors` is a named vector, so `scale_fill_mycolors()` looks up each value of
the mapped variable by name. The order of the bars, the order of the rows and
the order of the palette are all irrelevant: L4 is red because it is called L4.

```r
library(mycolorsTB)
library(ggplot2)

isolates <- data.frame(
  lineage = c("L1", "L2", "L3", "L4", "L5", "L6"),
  n       = c(37, 112, 64, 208, 9, 15)
)

ggplot(isolates, aes(x = lineage, y = n, fill = lineage)) +
  geom_col() +
  scale_fill_mycolors()
```

The names the palette knows are `A1` to `A4` and `L1` to `L10`. Anything else
is unmatched, which is covered below.

The colour version is the same scale on the `colour` aesthetic, which is what
you want for points and lines:

```r
pca <- data.frame(
  pc1     = c(-2.1, 0.4, 1.8, 2.6, -0.7, 0.1),
  pc2     = c( 1.2, -0.6, 0.3, -1.4, 2.0, -2.2),
  lineage = c("L2", "L4", "L4", "L1", "L2", "L4")
)

ggplot(pca, aes(pc1, pc2, colour = lineage)) +
  geom_point(size = 4) +
  scale_color_mycolors(name = "Lineage")
```

Both spellings of the aesthetic work on the ggplot side (`color` and `colour`),
but the package only ships the `color` spelling of the function name. There is
no `scale_colour_mycolors()`.

## Setting the legend

This is what `...` bought. A lineage code is a poor legend entry on a slide, and
fourteen of them in one column is a legend taller than the plot. `name`,
`labels` and `guide` fix both without leaving the palette behind:

```r
ggplot(isolates, aes(x = lineage, y = n, fill = lineage)) +
  geom_col() +
  scale_fill_mycolors(
    name   = "Lineage",
    labels = c(L1 = "L1 Indo-Oceanic",        L2 = "L2 East Asian",
               L3 = "L3 East African-Indian", L4 = "L4 Euro-American",
               L5 = "L5 West African 1",      L6 = "L6 West African 2"),
    guide  = guide_legend(ncol = 2)
  )
```

`labels` is given as a named vector so it is matched the same way the colours
are. An unnamed vector is matched positionally against the breaks instead, and
the breaks are the factor levels in order, so adding `L10` to this data puts it
second and hands `L2` the label written for `L3`, and so on down the legend. No
warning is raised, because the counts still agree.

To drop the legend entirely, pass `guide = "none"`:

```r
ggplot(pca, aes(pc1, pc2, colour = lineage)) +
  geom_point(size = 4) +
  scale_color_mycolors(guide = "none")
```

## When a group is not a lineage

This is the failure mode to know about, because it does not announce itself.

A value that is not a name in `mycolors` is not an error and not a warning. A
manual scale treats it as missing and fills it with `na.value`, whose default is
`"grey50"`.

```r
mixed <- data.frame(
  group = c("L2", "L4", "Beijing", "unknown"),
  n     = c(112, 208, 40, 6)
)

p <- ggplot(mixed, aes(x = group, y = n, fill = group)) +
  geom_col() +
  scale_fill_mycolors()

ggplot_build(p)$data[[1]]$fill
#> [1] "#001aff" "#ff0000" "grey50"  "grey50"
```

Two bars carry lineage colours and two carry grey. The plot renders, the code
exits cleanly, and nothing on screen says the palette declined to colour half
the data. Worse, the legend lists only `L2` and `L4`: the grey bars have no
legend entry at all, so the figure reads as if grey were a deliberate choice.

There are two ways to deal with it, and they answer different questions.

If the unmatched values are a mistake, catch them before plotting:

```r
setdiff(unique(mixed$group), names(mycolors))
#> [1] "Beijing" "unknown"
```

`character(0)` means every group has a colour. Anything else is the list of
groups that will come out grey. This is a one-line check worth keeping in any
script that builds a figure from data someone else labelled, because sublineage
codes (`L4.9`), spoligotype families (`Beijing`) and free-text placeholders
(`unknown`, `NA`, `-`) all pass through `mycolors` untouched.

If the unmatched values are real and you want them shown as such, make the
fallback deliberate rather than accidental. That is what `na.value` is for:

```r
ggplot(mixed, aes(x = group, y = n, fill = group)) +
  geom_col() +
  scale_fill_mycolors(name = "Lineage", na.value = "grey20")
```

Pick something that cannot be mistaken for a palette colour, and say in the
caption what it means. Grey50 next to fourteen saturated colours looks like a
fifteenth category; a dark neutral you chose on purpose looks like a decision.

## classicTB colours by position

`classicTB` holds the same fourteen colours as `mycolors` with the names
stripped off. An unnamed `values` vector is consumed in order, so the colours
are handed out by the order of the factor levels, not by what the levels are
called. That makes it the right scale for a categorical variable that has
nothing to do with lineages.

```r
resistance <- data.frame(
  drug = c("INH", "RIF", "EMB", "PZA", "STR"),
  pct  = c(12, 8, 4, 6, 3)
)

ggplot(resistance, aes(x = drug, y = pct, fill = drug)) +
  geom_col() +
  scale_fill_classicTB(guide = "none")
```

Here `EMB` gets the first palette colour and `STR` gets the fifth, because the
default factor levels are alphabetical. Reorder the levels and the colours move
with them. Two consequences follow:

* A figure built this way is not stable across datasets. Drop one drug from the
  next cohort and every colour after it shifts. If the mapping has to hold
  across figures, set it yourself with `scale_fill_manual(values = c(INH = ...))`.
* Never use the `classicTB` scales for lineage data. They will colour L1 with
  the first palette colour rather than with L1's colour, and the result looks
  entirely plausible while being wrong.

## More groups than the palette holds

A manual scale needs one value per level, and it refuses rather than recycling:

```r
many <- data.frame(
  region = sprintf("R%02d", 1:18),
  n      = seq(30, 200, length.out = 18)
)

ggplot(many, aes(x = region, y = n, fill = region)) +
  geom_col() +
  scale_fill_classicTB()
```

```text
Error in `palette()`:
! Insufficient values in manual scale. 18 needed but only 14 provided.
```

The error comes from ggplot2 at draw time, not from `scale_fill_classicTB()`,
so it appears when you print or save the plot rather than when you build it.

`tb_palette()` is the way out. Ask it for as many colours as you have levels and
feed the result to a plain manual scale:

```r
ggplot(many, aes(x = region, y = n, fill = region)) +
  geom_col() +
  scale_fill_manual(values = tb_palette(nrow(many), "classicTB"), guide = "none")
```

```text
Warning message:
Number of requested colors (18) is greater than the size of the 'classicTB' palette (14). Colors are interpolated.
```

The warning is the point, not noise to suppress. Interpolated colours are not
palette colours: `tb_palette(18, "classicTB")` returns `#9DE498` in second place
where the palette itself has `#8ef5c8`. Eighteen categories on a fourteen-colour
palette is eighteen categories nobody will tell apart anyway, so treat the
warning as a prompt to group the tail into an "other" category rather than as a
box to tick.

Below the palette size there is no interpolation and no warning, so
`tb_palette(5, "classicTB")` really is the first five palette colours. See
[Reference](reference.md#tb_palette) for the exact rule.

## Related pages

* [Palettes](palettes.md) for what the three palettes contain.
* [Reference](reference.md) for signatures, arguments and return values.
* [Troubleshooting](troubleshooting.md) for the grey-bar case and the
  insufficient-values error as symptoms rather than as topics.

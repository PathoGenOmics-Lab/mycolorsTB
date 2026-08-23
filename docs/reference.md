# Reference

Everything mycolorsTB exports, in four groups: the three palettes, the four
ggplot2 scales, the two helpers that show and generate colours, and the two tree
functions. Signatures and defaults are those of version 0.1.2.

This page is written by hand rather than generated from the `.Rd` files, so it
can say what each object is for and when to reach for something else. For the
same reason it can drift from the package. `?mycolorsTB` in R is always the
installed truth.

## Palettes

Three exported vectors. They are plain character vectors of hex codes, not
functions and not objects with a class, so everything you already do to a
character vector works: subset them, reverse them, pass them to base graphics,
pass them to `scale_fill_manual()`. [Palettes](palettes.md) shows them and
explains the choices behind them; this section is the contract.

### mycolors

A named character vector of 14 hex colours, one per lineage of the
*Mycobacterium tuberculosis* complex: `A1` to `A4` for the animal-adapted
lineages, `L1` to `L10` for the human-adapted ones.

```r
mycolors
```

```text
       A1        A2        A3        A4        L1        L2        L3        L4 
"#d1ae00" "#8ef5c8" "#73c2ff" "#ff9cdb" "#ff3091" "#001aff" "#8a0bd2" "#ff0000" 
       L5        L6        L7        L8        L9       L10 
"#995200" "#1eb040" "#fbff00" "#ff9d00" "#37ff30" "#8fbda1" 
```

The names are the whole point. They are what lets
[`scale_fill_mycolors()`](#scale_color_mycolors-and-scale_fill_mycolors) put L4's
colour on L4 no matter where L4 sits in the data, and they are what lets you pull
one colour out by name for an annotation or a highlight:

```r
mycolors[c("L2", "L4")]
#>        L2        L4 
#> "#001aff" "#ff0000" 
```

Use it for anything keyed by lineage. Do not use it for an arbitrary categorical
variable: the names then match nothing, and unmatched values are filled with
`na.value` in silence.

### classicTB

The same 14 colours, in the same order, with the names removed.

```r
identical(unname(mycolors), classicTB)
#> [1] TRUE
```

Use it when you want the palette's look on a variable that has nothing to do
with lineages, so that colours are handed out by position. Do not use it for
lineage data: position is not identity, and a positional scale will colour L1
with L1's neighbour's colour without complaining.

### pathogenomics

An unnamed character vector of 8 colours from the PathoGenOmics Lab theme.

```r
pathogenomics
#> [1] "#c01718" "#305595" "#3c5824" "#d9d0ca" "#9ec4e8" "#c0b3a7" "#fdf2f8" "#020203"
```

These are house colours for the furniture of a figure or a slide: panel
backgrounds, headers, annotation boxes, a two-colour or three-colour comparison.
They are not lineage colours, and unlike the other two palettes no scale
function wraps them. Reach them through `tb_palette(n, "pathogenomics")` or
straight through `ggplot2::scale_fill_manual(values = pathogenomics)`.

Note that the palette runs from near-white (`#fdf2f8`) to near-black
(`#020203`), so several of its members are unreadable against a default panel
background and against each other. It is a theme, not a sequence of eight
distinguishable categories.

## Scales

Four functions, all of them wrappers one line long, all of them returning a
ggplot2 scale object that you add to a plot with `+`. Worked examples are on
[Using with ggplot2](ggplot2.md); this section is the contract.

### scale_color_mycolors() and scale_fill_mycolors()

```r
scale_color_mycolors(...)
scale_fill_mycolors(...)
```

| Argument | Type | Default | Meaning |
|---|---|---|---|
| `...` | any | none | Passed unchanged to `ggplot2::scale_colour_manual()` or `ggplot2::scale_fill_manual()`. |

There are no other arguments. `values` is set to `mycolors` and cannot be
overridden: passing `values` yourself is an error, `formal argument "values"
matched by multiple actual arguments`. To supply your own colours, call
`ggplot2::scale_fill_manual()` directly.

**Returns** a ggplot2 discrete scale for the `colour` or `fill` aesthetic.

The arguments worth knowing about are `name` (legend title), `labels` (legend
text, best given as a named vector so it is matched the same way the colours
are), `breaks` (which entries appear and in what order), `na.value` (the colour
for a value the palette has no name for, default `"grey50"`) and
`guide` (`"none"` to drop the legend, or a `guide_legend()` call to reshape it).

```r
library(ggplot2)

isolates <- data.frame(
  lineage = c("L1", "L2", "L3", "L4"),
  n       = c(37, 112, 64, 208)
)

ggplot(isolates, aes(x = lineage, y = n, fill = lineage)) +
  geom_col() +
  scale_fill_mycolors(name = "Lineage", guide = guide_legend(ncol = 2))
```

`...` is new in 0.1.2. On 0.1.1 these functions took no arguments and any of
the calls above is an error there.

Only the `color` spelling exists. `scale_colour_mycolors()` is not exported.

### scale_color_classicTB() and scale_fill_classicTB()

```r
scale_color_classicTB(...)
scale_fill_classicTB(...)
```

| Argument | Type | Default | Meaning |
|---|---|---|---|
| `...` | any | none | Passed unchanged to `ggplot2::scale_colour_manual()` or `ggplot2::scale_fill_manual()`. |

**Returns** a ggplot2 discrete scale for the `colour` or `fill` aesthetic.

Identical to the pair above except that `values` is `classicTB`, which is
unnamed, so colours go to factor levels in order. Reordering the levels reorders
the colours.

```r
resistance <- data.frame(
  drug = c("INH", "RIF", "EMB", "PZA"),
  pct  = c(12, 8, 4, 6)
)

ggplot(resistance, aes(x = drug, y = pct, fill = drug)) +
  geom_col() +
  scale_fill_classicTB(guide = "none")
```

These scales carry 14 values and a manual scale needs one per level, so 15 or
more levels is an error at draw time, not a recycled palette. Use
[`tb_palette()`](#tb_palette) with `scale_fill_manual()` when you have more
categories than that.

## Preview and generation

### view_palette()

```r
view_palette(palette_name = "mycolors")
```

| Argument | Type | Default | Meaning |
|---|---|---|---|
| `palette_name` | single character string | `"mycolors"` | One of `"mycolors"`, `"classicTB"`, `"pathogenomics"`. Matched with `match.arg()`, so unambiguous abbreviations such as `"myc"` work. |

**Returns** a ggplot object: one tile per colour, the hex code written across
each tile, the palette name as the plot title, no legend.

```r
view_palette("pathogenomics")
```

The hex code on each tile is written in black or white, whichever stays readable
on that tile, chosen from the WCAG relative luminance of the colour underneath.
That is why `#020203` in the `pathogenomics` palette is legible; before 0.1.2
every label was black and that one was not.

The x axis labels differ between palettes because they come from the vector's
names. `view_palette("mycolors")` labels the tiles `A1` to `L10`;
`view_palette("classicTB")` and `view_palette("pathogenomics")` have no names to
show and fall back to the hex codes, which then appear both on the tile and on
the axis beneath it.

This is a lookup aid, for answering "which one is L7" without opening the source.
It is a real ggplot object, so `ggsave()` works on it, but it is not a legend and
not a figure: it has no data behind it.

An invalid name is an error, not a fallback:

```r
view_palette("lab")
#> Error in match.arg(palette_name, choices) :
#>   'arg' should be one of "mycolors", "classicTB", "pathogenomics"

view_palette(1)
#> Error: `palette_name` must be a single palette name, one of: mycolors, classicTB, pathogenomics.
```

The second message exists because before 0.1.2 a non-character argument reached
`switch()` and quietly picked a palette by position.

### tb_palette()

```r
tb_palette(n, palette_name = "classicTB")
```

| Argument | Type | Default | Meaning |
|---|---|---|---|
| `n` | single non-negative whole number | none, required | How many colours to return. `0` returns `character(0)`. |
| `palette_name` | single character string | `"classicTB"` | One of `"mycolors"`, `"classicTB"`, `"pathogenomics"`, matched with `match.arg()`. |

**Returns** an unnamed character vector of `n` hex colours. Even with
`palette_name = "mycolors"` the result has no names, because the colours it
gives back are no longer guaranteed to correspond to lineages.

The rule is a threshold at the palette size:

* `n` at most the palette size: the first `n` colours of the palette, unchanged,
  no warning.
* `n` greater than the palette size: `n` colours interpolated across the palette
  with `grDevices::colorRampPalette()`, and a warning saying so.

```r
tb_palette(6)
#> [1] "#d1ae00" "#8ef5c8" "#73c2ff" "#ff9cdb" "#ff3091" "#001aff"

tb_palette(3, "pathogenomics")
#> [1] "#c01718" "#305595" "#3c5824"

identical(tb_palette(14, "classicTB"), classicTB)
#> [1] TRUE
```

```r
tb_palette(16, "pathogenomics")
```

```text
 [1] "#C01718" "#7C3352" "#39508C" "#345667" "#3A5733" "#70805B" "#B9B8A8"
 [8] "#C9CCD2" "#ADC7E0" "#A4C0DB" "#B4B8BC" "#C8BBB1" "#E4D8D7" "#ECE1E7"
[15] "#777175" "#020203"
Warning message:
Number of requested colors (16) is greater than the size of the 'pathogenomics' palette (8). Colors are interpolated.
```

Interpolated output is uppercase, which is a tell: `colorRampPalette()` writes
its own hex codes, and the palettes are stored in lowercase. If a vector of
colours comes back uppercase, it is not the palette.

The threshold is new in 0.1.2. Before it, every call interpolated, so
`tb_palette(5, "mycolors")` returned five colours that matched no lineage while
the function's own warning claimed interpolation only happened when you asked
for too many.

Use it to feed a manual scale when you have more categories than a palette
holds, or to colour base graphics. Do not use it for lineage data: it returns
colours by position and drops the names, so
[`scale_fill_mycolors()`](#scale_color_mycolors-and-scale_fill_mycolors) is the
right tool there.

Both arguments are validated:

```r
tb_palette(5, 2)
#> Error: `palette_name` must be a single palette name, one of: mycolors, classicTB, pathogenomics.

tb_palette(1.5)
#> Error: `n` must be a single non-negative whole number.

tb_palette("classicTB")
#> Error: `n` must be a single non-negative whole number.
```

That last one catches a real slip: `n` comes first, so a lone palette name is
read as the count.

## Trees

Both need ggtree, which is a Bioconductor package and does not arrive with
`install.packages()`. See [Trees](trees.md) for the full picture
and for how to prepare a tree whose tips are sample names.

### plot_tb_tree()

```r
plot_tb_tree(newick_text)
```

| Argument | Type | Default | Meaning |
|---|---|---|---|
| `newick_text` | single character string | none, required | One tree in Newick format. Not a file path, not a `phylo` object, not a vector of trees. |

**Returns** a ggplot object built by ggtree: a phylogram with branch lengths,
ladderized, tips marked with a point and labelled, both coloured by
`scale_color_mycolors()`, no legend, and the x axis widened by a quarter to
leave room for the labels.

```r
tree_text <- "(L8,((L1,(L7,(L4,(L2,L3)))),(L5,((A2,(A3,A4)),(A1,(L10,(L6,L9)))))));"
plot_tb_tree(tree_text)
```

Tip labels are matched against the names of `mycolors`, so a tip that is not
called `A1` to `A4` or `L1` to `L10` is drawn in the manual scale's `na.value`.
There is no way to pass `na.value` in through this function.

Input that is not one parseable tree is rejected:

```r
plot_tb_tree("(L1,L2")
#> Error: `newick_text` could not be parsed as a single tree in Newick format.

plot_tb_tree(c("(L1,L2);", "(L3,L4);"))
#> Error: `newick_text` must be a single character string in Newick format.
```

Before 0.1.2 the first of those built a plot over an empty axis range instead.

### plot_tb_cladogram()

```r
plot_tb_cladogram(newick_text)
```

| Argument | Type | Default | Meaning |
|---|---|---|---|
| `newick_text` | single character string | none, required | Same as above, and validated the same way. |

**Returns** a ggplot object built by ggtree with `branch.length = "none"`, so
nodes are evenly spaced and only the topology is shown. Otherwise as
`plot_tb_tree()`, except that the x axis is widened by half rather than a
quarter, because the labels all start at the same place, and that the plot
carries the fixed title `TB Lineage Cladogram`.

```r
plot_tb_cladogram(tree_text)
```

The title is not an argument. Override it the way you would on any ggplot:

```r
plot_tb_cladogram(tree_text) + ggplot2::labs(title = "MTBC topology")
```

Use it when branch lengths would mislead or are not comparable, and
`plot_tb_tree()` when distance is part of what the figure is saying.

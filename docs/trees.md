# Trees

Two functions draw a phylogeny with the tips coloured by lineage:

```r
plot_tb_tree(newick_text)
plot_tb_cladogram(newick_text)
```

Both take exactly one argument, a single character string holding one tree in
Newick format, and both return a ggplot object built by
[ggtree](https://bioconductor.org/packages/ggtree). Nothing else is
configurable: there is no argument for the palette, the tip label size, the
layout or the title. What you can configure, you configure afterwards, by adding
layers to the object they hand back.

!!! warning "ggtree comes from Bioconductor"

    `install.packages("mycolorsTB")` will not get you ggtree, because ggtree is
    not on CRAN. Install it first, and only once:

    ```r
    if (!requireNamespace("BiocManager", quietly = TRUE)) {
      install.packages("BiocManager")
    }
    BiocManager::install("ggtree")
    ```

    The palette objects and the four ggplot2 scales work without it. Only these
    two functions need it.

## Tip labels have to be lineage names

Both functions colour tips with `scale_color_mycolors()`, which matches by name.
The tip labels in the Newick string are therefore the whole colouring key: a tip
called `L4` is red, and a tip called `ERR1234567` is grey, whatever lineage that
sample actually belongs to. There is no metadata argument and no join.

```r
library(mycolorsTB)

tree_text <- "(L8,((L1,(L7,(L4,(L2,L3)))),(L5,((A2,(A3,A4)),(A1,(L10,(L6,L9)))))));"
plot_tb_tree(tree_text)
```

That string is the reference topology of the *M. tuberculosis* complex used
throughout this package, with all fourteen tips named after the fourteen colours
in `mycolors`, so every tip lands.

Check a tree you did not write before you draw it:

```r
tree <- ape::read.tree(text = tree_text)
setdiff(tree$tip.label, names(mycolors))
#> character(0)
```

`character(0)` means every tip has a colour. Anything else is the list of tips
that will come out grey, silently, exactly as described for the bar charts in
[Using with ggplot2](ggplot2.md#when-a-group-is-not-a-lineage).

If the tips are sample identifiers, relabel them before plotting. `ape` keeps
the labels in a plain character vector, so this is an assignment:

```r
tree <- ape::read.tree(text = "(sample1,(sample2,sample3));")
tree$tip.label
#> [1] "sample1" "sample2" "sample3"

tree$tip.label <- c("L2", "L4", "L1")
ape::write.tree(tree)
#> [1] "(L2,(L4,L1));"

plot_tb_tree(ape::write.tree(tree))
```

The round trip through `ape::write.tree()` is needed because the functions take
Newick text, not a `phylo` object. Passing the object itself is an error:

```text
`newick_text` must be a single character string in Newick format.
```

Relabelling collapses samples onto lineages, so several tips will share a name
and share a colour. That is usually what you want from a lineage-coloured tree,
but it does mean the tip labels stop identifying individual samples.

## Reading a tree from a file

`readLines()` gives one element per line, and the functions want one string, so
collapse it:

```r
newick <- paste(readLines("lineages.nwk", warn = FALSE), collapse = "")
plot_tb_tree(newick)
```

A Newick file split across lines and read without the `paste()` produces a
character vector of length greater than one, which is rejected by the same
message as above.

## Which of the two to use

They differ in one setting and one label.

`plot_tb_tree()` draws the tree with its branch lengths, so horizontal distance
is evolutionary distance and the tips do not line up. Use it when the branch
lengths mean something: a maximum-likelihood tree, a distance tree, anything
where the reader should be able to see that two lineages are far apart.

`plot_tb_cladogram()` passes `branch.length = "none"` to ggtree, which throws
the branch lengths away and spaces the nodes evenly, so the plot shows only who
groups with whom. It also carries a fixed title, `TB Lineage Cladogram`. Use it
for topology alone: a schematic of the complex, a slide about which lineages are
sisters, a tree whose branch lengths are not comparable in the first place.

```r
plot_tb_cladogram(tree_text)
```

Both ladderize the tree and both reserve room on the right for the tip labels,
which the cladogram needs more of because its labels all end at the same x.

## Changing what they drew

The return value is an ordinary ggplot object, so the usual `+` works and the
usual `ggsave()` works:

```r
library(ggplot2)

p <- plot_tb_tree(tree_text) +
  labs(title = "MTBC reference topology") +
  theme(plot.title = element_text(face = "bold"))

ggsave("mtbc.png", p, width = 6, height = 6, dpi = 300)
```

Two things do not work by adding a layer. The legend is switched off inside both
functions with `theme(legend.position = "none")`; adding
`theme(legend.position = "right")` brings it back, but it will be a legend of
tip labels, one key per tip, which is rarely worth the space. And adding a
second colour scale replaces the palette rather than extending it, so
`scale_color_viridis_d()` on top of `plot_tb_tree()` throws the lineage colours
away and says so:

```text
Scale for colour is already present.
Adding another scale for colour, which will replace the existing scale.
```


If you need more than these two functions offer, call ggtree directly and use
`scale_color_mycolors()` as one layer among your own. That is all these
functions do.

## Malformed input is rejected

Before 0.1.2, `ape::read.tree()` returned `NULL` for input it could not parse
and the functions carried on, building a plot over an empty axis range. You got
a blank panel and no explanation. Since 0.1.2 the parse result is checked and
the failure is reported where it happens.

| Input | Result |
|---|---|
| `plot_tb_tree("(L1,L2")` | `` `newick_text` could not be parsed as a single tree in Newick format.`` |
| `plot_tb_tree("(L1,L2);(L3,L4);")` | same message: two trees in one string is not one tree |
| `plot_tb_tree(c("(L1,L2);", "(L3,L4);"))` | `` `newick_text` must be a single character string in Newick format.`` |
| `plot_tb_tree(NA_character_)` | same message |
| `plot_tb_tree(42)` | same message |
| `plot_tb_tree(ape::read.tree(text = "(L1,L2);"))` | same message: a `phylo` object is not a string |

The two messages divide the work between them. The first one means the argument
was the right shape and `ape` could not make one tree out of it. The second means
the argument was never a single string to begin with, and is raised before `ape`
is called at all.

Some malformed strings fail inside `ape` before the check is reached, and then
you see `ape`'s message rather than this package's. `plot_tb_tree("(L1,L2;")`
reports `numbers of left and right parentheses in Newick string not equal`,
which is more specific than anything the wrapper could say, so it is left
alone.

## Related pages

* [Reference](reference.md#plot_tb_tree) for the signatures and return
  values.
* [Troubleshooting](troubleshooting.md) if the tree builds but fails when you
  print it.

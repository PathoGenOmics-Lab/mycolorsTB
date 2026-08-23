# mycolorsTB 

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/PathoGenOmics-Lab/mycolorsTB/main/images/mycolors_dark.png">
    <img alt="mycolorsTB logo: a hand-drawn radial tree of the Mycobacterium tuberculosis complex with its branches coloured by lineage, beside the hand-lettered mycolorsTB name and drawn tuberculosis bacilli" src="https://raw.githubusercontent.com/PathoGenOmics-Lab/mycolorsTB/main/images/mycolors.png" title="mycolors logo" width="650" style="max-width: 100%;">
  </picture>
</p>

### R Color Package for _Mycobacterium tuberculosis_ complex

`mycolorsTB` is an R package that provides color palettes and helper functions to visualize genomic and epidemiological data from the _Mycobacterium tuberculosis_ complex, integrating with `ggplot2` and `ggtree`.

[Documentation](https://pathogenomics-lab.github.io/mycolorsTB/) · [Installation](#installation) · [Usage](#usage-and-examples) · [Color reference](#color-reference) · [Report an issue](https://github.com/PathoGenOmics-Lab/mycolorsTB/issues)

---

## Installation

You can install the stable version of `mycolorsTB` from CRAN or the development version from GitHub.

### Stable Version from CRAN (Recommended)

This is the easiest way to install the package for most users.

```r
install.packages("mycolorsTB")
```

**Note on Dependencies:** `mycolorsTB` requires the `ggtree` package from Bioconductor. If you don't have it installed, you can add it by running:

```r
if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
}
BiocManager::install("ggtree")
```

---

### Development Version from GitHub

Install this version if you want the latest features or fixes that have not yet been released to CRAN.

**1. Install BiocManager and Dependencies**

First, ensure you have `BiocManager` and the core dependencies `ggtree`, `ggplot2`, and `ape`.

```r
if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
}
BiocManager::install("ggtree")
install.packages(c("ggplot2", "ape", "remotes"))
```

**2. Install mycolorsTB**

Finally, install the package from GitHub using `remotes`.

```r
remotes::install_github("PathoGenOmics-Lab/mycolorsTB")
```

---

## Usage and Examples

### Available Color Palettes

You can access the color vectors directly:

```r
library(mycolorsTB)

# Vector with lineage names (A1, L1, etc.)
show(mycolorsTB::mycolors)

# Vector of pure colors, without names
show(mycolorsTB::classicTB) 
```

<p align="center">
<img alt="The 14 mycolorsTB colours as a two-row grid of swatches, each labelled with its hex code and its colour name, from Gold (metallic) through Cambridge blue" src="https://raw.githubusercontent.com/PathoGenOmics-Lab/mycolorsTB/main/images/mycolores.png" title="mycolors palette" width="1000">
</p>

### Example with `ggplot2`

Use `scale_fill_mycolors()` or `scale_color_mycolors()` to easily apply the palettes to your plots.

```r
library(ggplot2)

# Example data. The seed is fixed so this snippet uses the same data as the
# figure below, which is rendered by .github/scripts/make_example_plots.R.
set.seed(42)
data <- data.frame(
  x = 1:14,
  y = rnorm(14),
  group = names(mycolorsTB::mycolors)
)

# Bar plot using the default palette
ggplot(data, aes(x = x, y = y, fill = group)) +
  geom_bar(stat = "identity") +
  scale_fill_mycolors() +
  theme_minimal()
```

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/PathoGenOmics-Lab/mycolorsTB/main/images/example1_dark.png">
    <img alt="Bar chart of the example data with one bar per lineage, each bar filled with its mycolorsTB colour, and a legend on the right naming all 14 lineages" src="https://raw.githubusercontent.com/PathoGenOmics-Lab/mycolorsTB/main/images/example1.png" title="mycolors palette" width="1000" style="max-width: 100%;">
  </picture>
</p>

---

## Documentation

**<https://pathogenomics-lab.github.io/mycolorsTB/>** is the manual: what each
palette is for, every export with its signature and defaults, and the failures
that come up when a plot or a tree refuses to draw. The same pages are in
[`docs/`](docs/) in this repository.

| | |
|---|---|
| [Getting started](https://pathogenomics-lab.github.io/mycolorsTB/getting-started/) | Installing in the right order, because `ggtree` comes from Bioconductor and `install.packages()` does not know about it |
| [Palettes](https://pathogenomics-lab.github.io/mycolorsTB/palettes/) | The three palettes, what the names mean, and which one to reach for |
| [Using with ggplot2](https://pathogenomics-lab.github.io/mycolorsTB/ggplot2/) | The four scale functions, and when colours are matched by lineage name rather than by position |
| [Trees](https://pathogenomics-lab.github.io/mycolorsTB/trees/) | `plot_tb_tree()` and `plot_tb_cladogram()`, and why the tip labels have to be lineage names |
| [Reference](https://pathogenomics-lab.github.io/mycolorsTB/reference/) | All eleven exports, one entry each |
| [Troubleshooting](https://pathogenomics-lab.github.io/mycolorsTB/troubleshooting/) | Failures people have actually hit, including the `ggtree` and `ggplot2` pairing that breaks tree tip labels |

Release notes live in [NEWS.md](NEWS.md) and are rendered on the site as the
[changelog](https://pathogenomics-lab.github.io/mycolorsTB/changelog/).

---

## Color Reference

### HEX Codes

- **A1:** `#d1ae00`
- **A2:** `#8ef5c8`
- **A3:** `#73c2ff`
- **A4:** `#ff9cdb`
- **L1:** `#ff3091`
- **L2:** `#001aff`
- **L3:** `#8a0bd2`
- **L4:** `#ff0000`
- **L5:** `#995200`
- **L6:** `#1eb040`
- **L7:** `#fbff00`
- **L8:** `#ff9d00`
- **L9:** `#37ff30`
- **L10:** `#8fbda1`

### Example Newick Tree
```
(L8,((L1,(L7,(L4,(L2,L3)))),(L5,((A2,(A3,A4)),(A1,(L10,(L6,L9)))))));
```

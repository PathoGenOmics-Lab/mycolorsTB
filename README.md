# mycolorsTB 

<p align="center">
  <img src="https://github.com/PathoGenOmics-Lab/mycolorsTB/blob/main/images/mycolors.png" title="mycolors logo" style="width:650px; height: auto;">
</p>

### R Color Package for _Mycobacterium tuberculosis_ complex

`mycolorsTB` is an R package that provides color palettes and helper functions to visualize genomic and epidemiological data from the _Mycobacterium tuberculosis_ complex, integrating with `ggplot2` and `ggtree`.

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
<img src="https://github.com/PathoGenOmics-Lab/mycolorsTB/blob/main/images/mycolores.png" title="mycolors palette" style="width:1000px; height: auto;">
</p>

### Example with `ggplot2`

Use `scale_fill_mycolors()` or `scale_color_mycolors()` to easily apply the palettes to your plots.

```r
library(ggplot2)

# Example data
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
<img src="https://github.com/PathoGenOmics-Lab/mycolorsTB/blob/main/images/example1.png" title="mycolors palette" style="width:1000px; height: auto;">
</p>

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

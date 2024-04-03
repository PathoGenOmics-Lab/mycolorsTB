# mycolorsTB
<p align="center">
  <img src="https://github.com/PathoGenOmics-Lab/mycolorsTB/blob/main/images/mycolors.png" title="AMAP logo" style="width:650px; height: auto;">
</p>

### R Color package for Mycobacterium tuberculosis complex

## Installation
You can install the released version of mycolorsTB from GitHub
with:

``` r
install.packages("devtools")
devtools::install_github("ConesaLab/RColorConesa")
```
## Vector of colors
``` r
show(mycolorsTB::mycolors)
show(mycolorsTB::classicTB)
```
## Example - ggplot()
```
library(ggplot2)
library(mycolorsTB)

# Example data
data <- data.frame(
  x = 1:14,
  y = rnorm(14),
  group = rep(c(paste0("A", 1:4), paste0("L", 1:10)), each = 1)
)

# Fill: Plot with mycolors lineages names lineages names
ggplot(data, aes(x = x, y = y, fill = group)) +
  geom_bar(stat = "identity") + # scale_fill_manual(values = mycolors)
  scale_fill_mycolors() +
  theme_minimal()
```

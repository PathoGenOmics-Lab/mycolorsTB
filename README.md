# mycolorsTB
<p align="center">
  <img src="https://github.com/PathoGenOmics-Lab/mycolorsTB/blob/main/images/mycolors.png" title="mycolors logo" style="width:650px; height: auto;">
</p>

### R Color package for _Mycobacterium tuberculosis_ complex

## Installation
You can install the released version of mycolorsTB from GitHub
with:

``` r
install.packages("devtools")
devtools::install_github("PathoGenOmics-Lab/mycolorsTB")
```
## Vector of colors
``` r
show(mycolorsTB::mycolors) #vector with lineage names
show(mycolorsTB::classicTB) #vector witout lineage names
```
<p align="center">
  <img src="https://github.com/PathoGenOmics-Lab/mycolorsTB/blob/main/images/mycolores.png" title=mycolors palette" style="width:1000px; height: auto;">
</p>

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
  geom_bar(stat = "identity") + 
  scale_fill_mycolors() + # scale_fill_manual(values = mycolors)
  theme_minimal()
```
<p align="center">
  <img src="https://github.com/PathoGenOmics-Lab/mycolorsTB/blob/main/images/example1.png" title=mycolors palette" style="width:1000px; height: auto;">
</p>

## HEX codes
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



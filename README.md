# WafflePlots

Making waffle plots in Igor Pro

Intended for visualisation of microscopy colocalization data. Instead of using Venn or Euler diagrams, waffle plots allow us to get a feel of object-based colocalisation (sometimes referred to as co-occupation).

![img](img/allwafflePlotLayout.png)

## Limitations

- Uses circles only (any shape is possible but requires more development)
- Shows two groups and their intersection only (hard coded to color green/yellow/red)

## Example

```
WaffleMaker(33,12,62,9,0)
WaffleMaker(11,1,57,9,1)
WaffleMaker(0,0,55,8,2)
EqualiseWaffles() // makes all waffles the same size
PXPUtils#MakeTheLayouts("wafflePlot",0,6, alphaSort = 1, saveIt = 0)
```

## Requirements

- `PXPUtils.ipf` - available [here](https://github.com/quantixed/PXPUtils) - to display waffles easily
- Tested on Igor Pro 8 and 9, macOS

# SwiftContour

Compute contour polygons using marching squares in Swift

This is a port of [d3-contour](https://github.com/d3/d3-contour) and [contour-rs](https://github.com/mthh/contour-rs) to Swift.

## Installation

### Swift Package Manager

Add this repo as a package dependency:

## Usage

The contour builder computes outlined or filled contours and return them as GeoJSON Features:

```swift
import SwiftContour

let values = [
    [0.0, 0.0, 0.0, 0.0, 0.0],
    [0.0, 1.0, 1.0, 1.0, 0.0],
    [0.0, 1.0, 1.0, 1.0, 0.0],
    [0.0, 1.0, 1.0, 1.0, 0.0],
    [0.0, 0.0, 0.0, 0.0, 0.0]
]

let builder = ContourBuilder(dx: 10, dy: 10, smooth: true)

// Compute MultiLineString outlines
let lines: [Feature] = try builder.lines(values: data, thresholds: [0.5])

// Compute filled MultiPolygons
let contours: [Feature] = try builder.contours(values: data, thresholds: [0.5])
```

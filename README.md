# SwiftContour

Compute contour polygons using marching squares in Swift

This is a port of [d3-contour](https://github.com/d3/d3-contour) to Swift.

## Installation

### Swift Package Manager

Add this repo as a package dependency:

## Usage

The contour builder computes filled contours and return them as GeoJSON MultiPolygon Features:

```swift
import SwiftContour

let values = [
    [0.0, 0.0, 0.0, 0.0, 0.0],
    [0.0, 1.0, 1.0, 1.0, 0.0],
    [0.0, 1.0, 1.0, 1.0, 0.0],
    [0.0, 1.0, 1.0, 1.0, 0.0],
    [0.0, 0.0, 0.0, 0.0, 0.0]
]

// Compute filled MultiPolygons
let contours: [Feature] = try contours(values: data, width: 10, height: 10, thresholds: [0.5], smoothing: true)

// Compute MultiLineString Outlines
let lines: [Feature] = try lines(values: data, width: 10, height: 10, thresholds: [0.5], smoothing: true)
```

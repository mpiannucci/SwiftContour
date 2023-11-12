//
//  Contour.swift
//
//
//  Created by Matthew Iannucci on 11/11/23.
//

import Foundation
import GeoJSON
import AnyCodable

/// Contours generator, using builder pattern, to
/// be used on a rectangular `Slice` of values
///
struct ContourBuilder {
    /// The number of columns in the grid
    let dx: Int
    /// The number of rows in the grid
    let dy: Int
    /// Whether to smooth the contours
    let smooth: Bool
    /// The horizontal coordinate for the origin of the grid.
    let xOrigin: Double
    /// The vertical coordinate for the origin of the grid.
    let yOrigin: Double
    /// The horizontal step for the grid
    let xStep: Double
    /// The vertical step for the grid
    let yStep: Double
    
    init(dx: Int, dy: Int, smooth: Bool, xOrigin: Double = 0.0, yOrigin: Double = 0.0, xStep: Double = 1.0, yStep: Double = 1.0) {
        self.dx = dx
        self.dy = dy
        self.smooth = smooth
        self.xOrigin = xOrigin
        self.yOrigin = yOrigin
        self.xStep = xStep
        self.yStep = yStep
    }
    
    func smoooth_linear(ring: inout Ring, values: [Double], value: Double) {
        let len_values = values.count
        
        for var point in ring {
            let x = point.x
            let y = point.y
            let xt = Int(floor(x))
            let yt = Int(floor(y))
            var v0: Double = 0.0;
            let ix: Int = (yt * dx + xt)
            if ix < len_values {
                let v1 = values[ix];
                if x > 0.0 && x < (Double(dx) as Double) && abs(Double(xt) as Double - x) < Double.ulpOfOne {
                    v0 = values[(yt * dx + xt - 1)]
                    point.x = x + (value - v0) / (v1 - v0) - 0.5
                }
                if y > 0.0 && y < (Double(dy)) && abs(Double(yt) - y) < Double.ulpOfOne {
                    v0 = values[((yt - 1) * dx + xt)]
                    point.y = y + (value - v0) / (v1 - v0) - 0.5
                }
            }
        }
    }
    
    func line(
        values: [Double],
        threshold: Double,
        isoring: inout IsoRingBuilder
    ) throws -> MultiLineString {
        var result = isoring.compute(values: values, threshold: threshold)
        var linestrings: [LineString] = []
        
        for (index, _) in result.enumerated() {
            // Smooth the ring if needed
            if self.smooth {
                self.smoooth_linear(ring: &result[index], values: values, value: threshold)
            }
            
            // Compute the polygon coordinates according to the grid properties if needed
            let line: [Position] = result[index].map{point in
                return Position(longitude: point.x * self.xStep + self.xOrigin, latitude: point.y * self.yStep + self.yOrigin)
            }
            
            linestrings.append(try LineString(coordinates: line))
        }
        
        return MultiLineString(coordinates: linestrings)
    }
    
    /// Computes isolines according the given input `values` and the given `thresholds`.
    /// Returns an `Array` of GeoJSON Features of MultiLineString
    /// The threshold value of each Feature is stored in its `value` property.
    ///
    /// # Arguments
    ///
    /// * `values` - The slice of values to be used.
    /// * `thresholds` - The slice of thresholds values to be used.
    public func lines(values: [Double], thresholds: [Double]) throws -> [Feature] {
        if values.count != self.dx * self.dy {
            throw ContourError.dimensionError
        }
        
        var isoring = IsoRingBuilder(dx: self.dx, dy: self.dy);
        
        return try thresholds.map({threshold in
            let lines = try self.line(values: values, threshold: threshold, isoring: &isoring)
            let geometry = Geometry.multiLineString(lines)
            return Feature(
                geometry: geometry,
                properties: ["value": .init(threshold)]
            )
        })
    }
    
    func contour(
        values: [Double],
        threshold: Double,
        isoring: inout IsoRingBuilder
    ) throws -> MultiPolygon {
        var polygons: [Ring] = []
        var holes: [Ring] = []
        var holeIndexes: [Int: [Int]] = [:]
        var result = isoring.compute(values: values, threshold: threshold)
        
        for (index, _) in result.enumerated() {
            // Smooth the ring if needed
            if self.smooth {
                self.smoooth_linear(ring: &result[index], values: values, value: threshold)
            }
            
            // Compute the polygon coordinates according to the grid properties if needed
            let ring: Ring = result[index].map{point in
                return Pt(x: point.x * self.xStep + self.xOrigin, y: point.y * self.yStep + self.yOrigin)
            }
            
            if area(ring: ring) > 0.0 {
                holeIndexes[polygons.count] = []
                polygons.append(ring)
            } else {
                holes.append(ring)
            }
        }
        
        for (holeIndex, hole) in holes.enumerated() {
            for (polygonIndex, polygon) in polygons.enumerated() {
                if contains(ring: polygon, hole: hole) != -1 {
                    holeIndexes[polygonIndex]?.append(holeIndex)
                    break
                }
            }
        }
        
        let polys = try polygons.enumerated().map( { (index: Int, ring: Ring) in
            var rings = [try Polygon.LinearRing(ring: ring)]
            for interior in holeIndexes[index] ?? [] {
                rings.append(try Polygon.LinearRing(ring: holes[interior]))
            }
            
            return Polygon(coordinates: rings)
        })
        
        return MultiPolygon(coordinates: polys)
    }
    
    /// Computes contours according the given input `values` and the given `thresholds`.
    /// Returns an `Array` of GeoJSON Features of MultiPolygon
    /// The threshold value of each Feature is stored in its `value` property.
    ///
    /// # Arguments
    ///
    /// * `values` - The slice of values to be used.
    /// * `thresholds` - The slice of thresholds values to be used.
    public func contours(values: [Double], thresholds: [Double]) throws -> [Feature] {
        if values.count != self.dx * self.dy {
            throw ContourError.dimensionError
        }
        
        var isoring = IsoRingBuilder(dx: self.dx, dy: self.dy);
        
        return try thresholds.map({ threshold in
            let polygons = try self.contour(values: values, threshold: threshold, isoring: &isoring)
            let geometry = Geometry.multiPolygon(polygons)
            return Feature(
                geometry: geometry,
                properties: [
                    "value": .init(threshold)
                ]
            )
        })
    }
}

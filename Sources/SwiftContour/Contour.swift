//
//  Kt.swift
//
//
//  Created by Matthew Iannucci on 7/14/24.
//

import Foundation
import GeoJSON

public struct RingPoint {
    public var x: Double
    public var y: Double
}

extension Position {
    init(point: RingPoint) {
        self.init(longitude: point.x, latitude: point.y)
    }
}

internal typealias Stitch = (RingPoint, RingPoint)

internal typealias Ring = [RingPoint]

extension Ring {
    func point(index: Int) -> RingPoint {
        return self[index]
    }
}

extension LineString {
    init(ring: Ring) throws {
        try self.init(coordinates: ring.map({ Position(point: $0 )}))
    }
}

extension Polygon.LinearRing {
    init(ring: Ring) throws {
        try self.init(coordinates: ring.map({ Position(point: $0 )}))
    }
}

internal typealias MultiRing = [Ring]

extension MultiRing {
    func ring(index: Int) -> Ring {
        return self[index]
    }
}

internal class Fragment {
    var start: Int
    var end: Int
    var ring: Ring
    
    init(start: Int, end: Int, ring: Ring) {
        self.start = start
        self.end = end
        self.ring = ring
    }
}

//extension Fragment: Equatable {
//    public static func == (lhs: Fragment, rhs: Fragment) -> Bool {
//        return lhs.start == rhs.start && lhs.end == rhs.end
//    }
//}

public enum ContourError: Error {
    case dimensionError
}

internal func rp(x: Double, y: Double) -> RingPoint {
    return RingPoint(x: x, y: y)
}

extension Bool {
    func shl(bitCount: Int = 0) -> Int {
        return (self ? 1 : 0) << bitCount
    }
}

/**
 * Cases for stitching, contains 0, 1 or 2 possible "stitch case" as [Stitch], a Pair of ContourPoint
 */
private var cases: Array<Array<Stitch>> = [
    [],
    [Stitch(rp(x: 1.0, y: 1.5), rp(x: 0.5, y: 1.0))],
    [Stitch(rp(x: 1.5, y: 1.0), rp(x: 1.0, y: 1.5))],
    [Stitch(rp(x: 1.5, y: 1.0), rp(x: 0.5, y: 1.0))],
    [Stitch(rp(x: 1.0, y: 0.5), rp(x: 1.5, y: 1.0))],
    [Stitch(rp(x: 1.0, y: 1.5), rp(x: 0.5, y: 1.0)), Stitch(rp(x: 1.0, y: 0.5), rp(x: 1.5, y: 1.0))],
    [Stitch(rp(x: 1.0, y: 0.5), rp(x: 1.0, y: 1.5))],
    [Stitch(rp(x: 1.0, y: 0.5), rp(x: 0.5, y: 1.0))],
    [Stitch(rp(x: 0.5, y: 1.0), rp(x: 1.0, y: 0.5))],
    [Stitch(rp(x: 1.0, y: 1.5), rp(x: 1.0, y: 0.5))],
    [Stitch(rp(x: 0.5, y: 1.0), rp(x: 1.0, y: 0.5)), Stitch(rp(x: 1.5, y: 1.0), rp(x: 1.0, y: 1.5))],
    [Stitch(rp(x: 1.5, y: 1.0), rp(x: 1.0, y: 0.5))],
    [Stitch(rp(x: 0.5, y: 1.0), rp(x: 1.5, y: 1.0))],
    [Stitch(rp(x: 1.0, y: 1.5), rp(x: 1.5, y: 1.0))],
    [Stitch(rp(x: 0.5, y: 1.0), rp(x: 1.0, y: 1.5))],
    []
]

/**
 * Compute contour isolines as GeoJSON MultiLineStrings, given specified thresholds
 */
public func lines(values: Array<Double>, width: Int, height: Int, thresholds: Array<Double>, smoothing: Bool) throws -> [Feature] {
    return try thresholds.map { (threshold) in
        var lines: [[RingPoint]] = []
        
        isoRings(values: values, width: width, height: height, threshold: threshold) { currentRing in
            if (smoothing) {
                smoothLinear(ring: &currentRing, values: values, width: width, height: height, value: threshold)
            }
            
            lines.append(currentRing)
        }
        
        let lineStrings = try lines.map { ring in
            return try LineString(ring: ring)
        }
        
        let geometry = Geometry.multiLineString(MultiLineString(coordinates: lineStrings))
        return Feature(
            geometry: geometry,
            properties: ["value": .init(threshold)]
        )
    }
}

/**
 * Compute filled contours as GeoJSON MultiPolygons, given specified thresholds
 */
public func contours(values: Array<Double>, width: Int, height: Int, thresholds: Array<Double>, smoothing: Bool) throws -> [Feature] {
    let rings = try thresholds.map { (threshold) in
        var rings: [[[RingPoint]]] = []
        var holes: [[RingPoint]] = []
        
        isoRings(values: values, width: width, height: height, threshold: threshold) { currentRing in
            if (smoothing) {
                smoothLinear(ring: &currentRing, values: values, width: width, height: height, value: threshold)
            }
            
            if (doubleArea(ring: currentRing) > 0) {
                rings.append([currentRing])
            } else {
                holes.append(currentRing)
            }
        }
        
        // Adding found "holes" to their corresponding MultiRing container
        for hole in holes {
            for i in 0..<rings.count {
                let ring = rings[i]
                
                // The "container ring" (or external ring), is always the first in the array
                let container = ring[0]
                
                if (contains(ring: container, hole: hole) != -1) {
                    rings[i].append(hole)
                    break
                }
            }
        }
        
        let polygons = try rings.map { ring in
            try ring.map { r in
                return try Polygon.LinearRing(ring: r)
            }
        }
        
        return polygons
    }
    
    // Mapping "geoJson coordinates" to the expected format:
    // First build an array for each threshold
    return rings.enumerated().map { index, ring in
        let polygons = ring.map { r in
            return Polygon(coordinates: r)
        }
        
        let geometry = Geometry.multiPolygon(MultiPolygon(coordinates: polygons))
        return Feature(
            geometry: geometry,
            properties: [
                "value": .init(thresholds[index])
            ]
        )
        
    }
}

/**
 * Compute isoRings, given the data and specified thresholds
 */
internal func isoRings(values: Array<Double>, width: Int, height: Int, threshold: Double, callback: (inout [RingPoint]) -> Void) {
    var t0: Bool
    var t1: Bool
    var t2: Bool
    var t3: Bool
    var x = 0
    var y = 0
    
    func index(point: RingPoint) -> Int {
        return Int(point.x * 2.0 + point.y * (Double(width) + 1) * 4)
    }
    
    func _threshold(index: Int) -> Bool {
        return values[index] >= threshold
    }
    
    let maxSize = index(point: RingPoint(x: Double(width), y: Double(height)))
    var fragmentByStart: Array<Fragment?> = Array(repeating: nil, count: maxSize)
    var fragmentByEnd: Array<Fragment?> = Array(repeating: nil, count: maxSize)
    
    func stitch(stitch: Stitch) {
        let start = rp(x: stitch.0.x + Double(x), y: stitch.0.y + Double(y))
        let end = rp(x: stitch.1.x + Double(x), y: stitch.1.y + Double(y))
        let startIndex = index(point: start)
        let endIndex = index(point: end)
        var f = fragmentByEnd[startIndex]
        let g: Fragment?
        
        if let f = f {
            g = fragmentByStart[endIndex]
            if let g = g {
                fragmentByEnd[f.end] = nil
                fragmentByStart[g.start] = nil
                if (f === g) {
                    f.ring.append(end)
                    callback(&f.ring)
                } else {
                    let startEnd = Fragment(start: f.start, end: g.end, ring: (f.ring + g.ring))
                    fragmentByStart[f.start] = startEnd
                    fragmentByEnd[g.end] = startEnd
                }
            } else {
                fragmentByEnd[f.end] = nil
                f.ring.append(end)
                f.end = endIndex
                fragmentByEnd[endIndex] = f
            }
        } else {
            f = fragmentByStart[endIndex]
            if let f = f {
                g = fragmentByEnd[startIndex]
                if let g = g {
                    fragmentByStart[f.start] = nil
                    fragmentByEnd[g.end] = nil
                    if (f === g) {
                        f.ring.append(end)
                        callback(&f.ring)
                    } else {
                        let startEnd = Fragment(start: g.start, end: f.end, ring: (g.ring + f.ring))
                        fragmentByStart[g.start] = startEnd
                        fragmentByEnd[f.end] = startEnd
                    }
                } else {
                    fragmentByStart[f.start] = nil
                    f.ring.insert(start, at: 0)
                    f.start = startIndex
                    fragmentByStart[f.start] = f
                }
            } else {
                let startEnd = Fragment(start: startIndex, end: endIndex, ring: [start, end])
                fragmentByStart[startIndex] = startEnd
                fragmentByEnd[endIndex] = startEnd
            }
        }
    }
    
    // Special case for the first row (y = -1, t2 = t3 = 0).
    x = -1
    y = -1
    t1 = _threshold(index: 0)
    cases[t1.shl(bitCount: 1)].forEach(stitch)
    x += 1
    while (x < width - 1) {
        t0 = t1
        t1 = _threshold(index: x + 1)
        cases[(t0.shl()) | (t1.shl(bitCount: 1))].forEach(stitch)
        x += 1
    }
    cases[t1.shl()].forEach(stitch)
    
    // General case for the intermediate rows.
    y += 1
    while (y < (height - 1)) {
        x = -1
        t1 = _threshold(index: y * width + width)
        t2 = _threshold(index: y * width)
        cases[(t1.shl(bitCount: 1)) | (t2.shl(bitCount: 2))].forEach(stitch)
        x += 1
        while (x < (width - 1)) {
            t0 = t1
            t1 = _threshold(index: y * width + width + x + 1)
            t3 = t2
            t2 = _threshold(index: y * width + x + 1)
            cases[(t0.shl()) | (t1.shl(bitCount: 1)) | (t2.shl(bitCount: 2)) | (t3.shl(bitCount: 3))].forEach(stitch)
            x += 1
        }
        cases[(t1.shl()) | (t2.shl(bitCount: 3))].forEach(stitch)
        y += 1
    }
    
    // Special case for the last row (y = dy - 1, t0 = t1 = 0).
    x = -1
    t2 = _threshold(index: y * width)
    cases[t2.shl(bitCount: 2)].forEach(stitch)
    x += 1
    while (x < (width - 1)) {
        t3 = t2
        t2 = _threshold(index: y * width + x + 1)
        cases[(t2.shl(bitCount: 2)) | (t3.shl(bitCount: 3))].forEach(stitch)
        x += 1
    }
    cases[t2.shl(bitCount: 3)].forEach(stitch)
}

/**
 * Linear smoothing of the point of a ring
 */
private func smoothLinear(ring: inout [RingPoint], values: Array<Double>, width: Int, height: Int, value: Double) {
    for i in 0..<ring.count {
        let pt = ring[i]
        let x = pt.x
        let y = pt.y
        let xt = Int(x)
        let yt = Int(y)
        
        if (x > 0 && x < Double(width) && abs(Double(xt) - x) < Double.ulpOfOne) {
            let pointIndex = yt * width + xt
            let v0 = values[pointIndex - 1]
            let v1 = values[pointIndex]
            ring[i].x = x + (value - v0) / (v1 - v0) - 0.5
        }
        
        if (y > 0 && y < Double(height) && abs(Double(yt) - y) < Double.ulpOfOne) {
            let v0 = values[(yt - 1) * width + xt]
            let v1 = values[yt * width + xt]
            ring[i].y = y + (value - v0) / (v1 - v0) - 0.5
        }
    }
}

/**
 * return the double of the area of the ring. Positive if points are
 * counter-clockwise negative otherwise.
 */
internal func doubleArea(ring: Array<RingPoint>) -> Double {
    let n = ring.count
    var area = ring[n - 1].y * ring[0].x - ring[n - 1].x * ring[0].y
    for i in 1..<n {
        area += ring[i - 1].y * ring[i].x - ring[i - 1].x * ring[i].y
    }
    
    return area
}

/**
 * Check if a "hole" is contained in a "ring".
 * If any point of hole is inside the ring returns 1
 * If any point of hole is outside the ring returns -1
 * Else returns 0 (all points are on the ring)
 */
internal func contains(ring: [RingPoint], hole: [RingPoint]) -> Int {
    let n = hole.count
    for i in 0..<n {
        let c = ringContains(ring: ring, point: hole[i])
        if (c != 0) {
            return c
        }
    }
    return 0
}

/**
 * If point inside ring returns 1
 * If point on ring returns 0
 * If point outside ring returns -1
 */
internal func ringContains(ring: [RingPoint], point: RingPoint) -> Int {
    let x = point.x
    let y = point.y
    var contains = -1
    let n = ring.count
    var j = n - 1
    var i = 0
    
    while i < n {
        let pi = ring[i]
        let xi = pi.x
        let yi = pi.y
        let pj = ring[j]
        let xj = pj.x
        let yj = pj.y
        
        if (segmentContains(start: pi, end: pj, point: point)) {
            return 0
        }
        if (((yi > y) != (yj > y)) && ((x < (xj - xi) * (y - yi) / (yj - yi) + xi))) {
            contains = -contains
        }
        
        i += 1
        j = i
    }
    
    return contains
}

//if vertical compare y
internal func segmentContains(start: RingPoint, end: RingPoint, point: RingPoint) -> Bool {
    if collinear(a: start, b: end, c: point) {
        if (start.x == end.x) {
            return within(from: start.y, within: point.y, to: end.y)
        }
        else {
            return within(from: start.x, within: point.x, to: end.x)
        }
    } else {
        return false
    }
}

internal func within(from: Double, within: Double, to: Double) -> Bool {
    return from <= within && within <= to || to <= within && within <= from
}

internal func collinear(a: RingPoint, b: RingPoint, c: RingPoint) -> Bool {
    return (b.x - a.x) * (c.y - a.y) == (c.x - a.x) * (b.y - a.y)
}

internal func collinear(a: Array<Double>, b: Array<Double>, c: Array<Double>) -> Bool {
    return (b[0] - a[0]) * (c[1] - a[1]) == (c[0] - a[0]) * (b[1] - a[1])
}


//
//  File.swift
//  
//
//  Created by Matthew Iannucci on 11/11/23.
//

import Foundation

func collinear(a: Pt, b: Pt, c: Pt) -> Bool {
    return abs((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) < Double.ulpOfOne
}

func within(p: Double, q: Double, r: Double) -> Bool {
    return p <= q && q <= r || r <= q && q <= p
}

func segmentContaints(a: Pt, b: Pt, c: Pt) -> Bool {
    if collinear(a: a, b: b, c: c) {
        if abs(a.x - b.x) < Double.ulpOfOne {
            return within(p: a.y, q: c.y, r: b.y)
        } else {
            return within(p: a.x, q: c.x, r: b.x)
        }
    } else {
        return false
    }
}

func ringContains(ring: [Pt], point: Pt) -> Int {
    let x = point.x;
    let y = point.y;
    let n = ring.count;
    var contains = -1;
    var j = n - 1;
    for i in 0..<n {
        let pi = ring[i];
        let xi = pi.x;
        let yi = pi.y;
        let pj = ring[j];
        let xj = pj.x;
        let yj = pj.y;
        if segmentContaints(a: pi, b: pj, c: point) {
            return 0;
        }
        if ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
            contains = -contains;
        }
        j = i;
    }
    return contains
}

func area(ring: [Pt]) -> Double {
    var i = 0;
    let n = ring.count - 1;
    var area = ring[n - 1].y * ring[0].x - ring[n - 1].x * ring[0].y;
    while i < n {
        i += 1;
        area += ring[i - 1].y * ring[i].x - ring[i - 1].x * ring[i].y;
    }
    return area
}

func contains(ring: [Pt], hole: [Pt]) -> Int {
    var i = 0;
    let n = hole.count;
    var c: Int = 0;
    while i < n {
        c = ringContains(ring: ring, point: hole[i]);
        if c != 0 {
            return c;
        }
        i += 1;
    }
    return 0
}

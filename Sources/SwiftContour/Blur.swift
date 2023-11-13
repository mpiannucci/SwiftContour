//
//  Blur.swift
//
//  Ported from https://github.com/d3/d3-array/blob/main/src/blur.js
//
//  Created by Matthew Iannucci on 11/12/23.
//

import Foundation


func doubleEqual(_ first: Double, _ second: Double) -> Bool {
    return abs(first - second) < Double.ulpOfOne
}

typealias Blur = (inout [Double], [Double], Int, Int, Int) -> Void

// Like blurf, but optimized for integer radius.
func bluri(radius: Double) -> Blur {
    let w = 2.0 * radius + 1.0
    
    return { T, S, start, stop, step in
        let stop = stop - step
        
        // inclusive stop
        if (!(stop >= start)) {
            return
        }
        
        var sum = radius * S[start]
        let s = step * Int(radius)
        for i in stride(from: start, to: start + s, by: step) {
            sum += S[min(stop, i)]
        }
        
        for i in stride(from: start, through: stop, by: step) {
            sum += S[min(stop, i + s)]
            T[i] = sum / w
            sum -= S[max(start, i - s)]
        }
    }
}

// Given a target array T, a source array S, sets each value T[i] to the average
// of {S[i - r], …, S[i], …, S[i + r]}, where r = ⌊radius⌋, start <= i < stop,
// for each i, i + step, i + 2 * step, etc., and where S[j] is clamped between
// S[start] (inclusive) and S[stop] (exclusive). If the given radius is not an
// integer, S[i - r - 1] and S[i + r + 1] are added to the sum, each weighted
// according to r - ⌊radius⌋.
func blurf(radius: Double) -> Blur {
    let radius0 = floor(radius)
    if doubleEqual(radius0, radius) {
        return bluri(radius: radius)
    }
    
    let t = radius - radius0
    let w = 2 * radius + 1
    
    return { T, S, start, stop, step in
        let stop = stop - step
        
        // inclusive stop
        if (!(stop >= start)) {
                return
        };
        
        var sum = radius0 * S[start];
        let s0 = step * Int(radius0);
        let s1 = s0 + step;
        for i in stride(from: start, to: start + s0, by: step) {
            sum += S[min(stop, i)]
        }
        
        for i in stride(from: start, through: stop, by: step) {
            sum += S[min(stop, i + s0)];
            T[i] = (sum + t * (S[max(start, i - s1)] + S[min(stop, i + s1)])) / w;
            sum -= S[max(start, i - s0)];
        }
    }
}


public func blur(values: [Double], radius: Double) -> [Double] {
    var copied = values
    
    guard radius > 0, copied.count > 0 else {
        return copied
    }
    
    let length = copied.count
    let blurr = blurf(radius: radius);
    var temp = copied
    
    blurr(&copied, temp, 0, length, 1);
    blurr(&temp, copied, 0, length, 1);
    blurr(&copied, temp, 0, length, 1);
    
    return copied
}

func blurh(blurr: Blur, T: inout [Double], S: [Double], w: Int, h: Int) {
    var y = 0
    var y0 = 0
    while y < w * h {
        y0 = y
        y += w
        blurr(&T, S, y0, y, 1)
    }
}

func blurv(blurr: Blur, T: inout [Double], S: [Double], w: Int, h: Int) {
    let n = w * h
    for x in 0..<w {
        blurr(&T, S, x, x + n, w);
    }
}

public func blur2(values: [Double], width: Int, rx: Double, height: Int? = nil, ry: Double? = nil) -> [Double] {
    let ry = ry == nil ? rx : ry!
    let height = height == nil ? values.count / width : height!
    
    if rx < 0 || ry < 0 || width < 0 || height < 0 {
        return values
    }
    
    let blurx = blurf(radius: rx)
    let blury = blurf(radius: ry)
    var copy = values
    var temp = copy
    
    blurh(blurr: blurx, T: &temp, S: copy, w: width, h: height)
    blurh(blurr: blurx, T: &copy, S: temp, w: width, h: height)
    blurh(blurr: blurx, T: &temp, S: copy, w: width, h: height)
    blurv(blurr: blury, T: &copy, S: temp, w: width, h: height)
    blurv(blurr: blury, T: &temp, S: copy, w: width, h: height)
    blurv(blurr: blury, T: &copy, S: temp, w: width, h: height)
    
    return copy
}

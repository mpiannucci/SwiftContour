//
//  IsoRing.swift
//  
//
//  Created by Matthew Iannucci on 11/11/23.
//

import Foundation

let CASES = [
    [],
    [
        [
            [1.0, 1.5],
            [0.5, 1.0]
        ]
    ],
    [
        [
            [1.5, 1.0],
            [1.0, 1.5]
        ]
    ],
    [
        [
            [1.5, 1.0],
            [0.5, 1.0]
        ]
    ],
    [
        [
            [1.0, 0.5],
            [1.5, 1.0]
        ]
    ],
    [
        [
            [1.0, 1.5],
            [0.5, 1.0]
        ],
        [
            [1.0, 0.5],
            [1.5, 1.0]
        ]
    ],
    [
        [
            [1.0, 0.5],
            [1.0, 1.5]
        ]
    ],
    [
        [
            [1.0, 0.5],
            [0.5, 1.0]
        ]
    ],
    [
        [
            [0.5, 1.0],
            [1.0, 0.5]
        ]
    ],
    [
        [
            [1.0, 1.5],
            [1.0, 0.5]
        ]
    ],
    [
        [
            [0.5, 1.0],
            [1.0, 0.5]
        ],
        [
            [1.5, 1.0],
            [1.0, 1.5]
        ]
    ],
    [
        [
            [1.5, 1.0],
            [1.0, 0.5]
        ]
    ],
    [
        [
            [0.5, 1.0],
            [1.5, 1.0]
        ]
    ],
    [
        [
            [1.0, 1.5],
            [1.5, 1.0]
        ]
    ],
    [
        [
            [0.5, 1.0],
            [1.0, 1.5]
        ]
    ],
    []
]

/// Isoring generator to compute marching squares with isolines stitched into rings.
public struct IsoRingBuilder {
    var fragment_by_start: [Int:Int]
    var fragment_by_end: [Int:Int]
    var f: Slab<Fragment>
    let dx: Int
    let dy: Int
    var isEmpty: Bool
    
    /// Constructs a new IsoRing generator for a grid with `dx` * `dy` dimension.
    /// # Arguments
    ///
    /// * `dx` - The number of columns in the grid.
    /// * `dy` - The number of rows in the grid.
    init(dx: Int, dy: Int) {
        self.fragment_by_start = [:]
        self.fragment_by_end = [:]
        self.f = Slab()
        self.dx = dx
        self.dy = dy
        self.isEmpty = true
    }
    
    /// Computes isoring for the given slice of `values` according to the `threshold` value
    /// (the inside of the isoring is the surface where input `values` are greater than or equal
    /// to the given threshold value).
    ///
    /// # Arguments
    ///
    /// * `values` - The slice of values to be used.
    /// * `threshold` - The threshold value to use.
    public mutating func compute(values: [Double], threshold: Double) -> [Ring] {
        if !self.isEmpty {
            self.clear();
        }
        
        var result: [Ring] = []
        let dx = Int(self.dx)
        let dy = Int(self.dy)
        var x = -1
        var y = -1
        var t0: Int
        var t1: Int
        var t2: Int
        var t3: Int
        
        // Special case for the first row (y = -1, t2 = t3 = 0).
        t1 = values[0] >= threshold ? 1 : 0
        CASES[t1 << 1].forEach { ring in
            self.stitch(line: ring, x: x, y: y, result: &result)
        }
        x += 1
        
        while x < dx - 1 {
            t0 = t1;
            t1 = values[(x + 1)] >= threshold ? 1 : 0
            CASES[(t0 | t1 << 1)].forEach { ring in
                self.stitch(line: ring, x: x, y: y, result: &result)
            }
            x += 1;
        }
        CASES[t1].forEach { ring in
            self.stitch(line: ring, x: x, y: y, result: &result)
        }
        
        // General case for the intermediate rows.
        y += 1;
        while y < dy - 1 {
            x = -1;
            t1 = values[y * dx + dx] >= threshold ? 1 : 0;
            t2 = values[y * dx] >= threshold ? 1 : 0;
            CASES[(t1 << 1 | t2 << 2)].forEach { ring in
                self.stitch(line: ring, x: x, y: y, result: &result)
            }
            x += 1;
            
            while x < dx - 1 {
                t0 = t1;
                t1 = values[y * dx + dx + x + 1] >= threshold ? 1 : 0
                t3 = t2;
                t2 = values[y * dx + x + 1] >= threshold ? 1 : 0
                CASES[(t0 | t1 << 1 | t2 << 2 | t3 << 3)].forEach { ring in
                    self.stitch(line: ring, x: x, y: y, result: &result)
                }
                x += 1;
            }
            CASES[(t1 | t2 << 3)].forEach { ring in
                self.stitch(line: ring, x: x, y: y, result: &result)
            }
            y += 1;
        }
        
        // Special case for the last row (y = dy - 1, t0 = t1 = 0).
        x = -1;
        t2 = values[y * dx] >= threshold ? 1 : 0
        CASES[(t2 << 2)].forEach { ring in
            self.stitch(line: ring, x: x, y: y, result: &result)
        }
        x += 1;
        while x < dx - 1 {
            t3 = t2;
            t2 = values[y * dx + x + 1] >= threshold ? 1 : 0;
            CASES[(t2 << 2 | t3 << 3)].forEach { ring in
                self.stitch(line: ring, x: x, y: y, result: &result)
            }
            x += 1;
        }
        CASES[(t2 << 3)].forEach { ring in
            self.stitch(line: ring, x: x, y: y, result: &result)
        }
        
        self.isEmpty = false;
        return result
    }
    
    func index(point: Pt) -> Int {
        return Int(point.x * 2.0 + point.y * (Double(self.dx) + 1.0) * 4.0)
    }
    
    // Stitchs segments to rings.
    mutating func stitch(
        line: [[Double]],
        x: Int,
        y: Int,
        result: inout [Ring]
    ) {
        let start = Pt(x: line[0][0] + Double(x), y: line[0][1] + Double(y))
        let end = Pt(x: line[1][0] + Double(x), y: line[1][1] + Double(y))
        let startIndex = self.index(point: start)
        let endIndex = self.index(point: end)
        
        if let f_ix = self.fragment_by_end[startIndex] {
            if let g_ix = self.fragment_by_start[endIndex] {
                self.fragment_by_end.removeValue(forKey: startIndex)
                self.fragment_by_start.removeValue(forKey: endIndex)
                if f_ix == g_ix {
                    var f = self.f.pop(at: f_ix)!
                    f.ring.append(end);
                    result.append(f.ring);
                } else {
                    var f = self.f.pop(at: f_ix)!
                    let g = self.f.pop(at: g_ix)!
                    f.ring.append(contentsOf: g.ring)
                    let ix = self.f.put(item: Fragment(
                        start: f.start,
                        end: g.end,
                        ring: f.ring
                    ))
                    self.fragment_by_start[f.start] = ix
                    self.fragment_by_end[g.end] = ix
                }
            } else {
                self.fragment_by_end.removeValue(forKey: startIndex)
                self.f.inner[f_ix]?.ring.append(end)
                self.f.inner[f_ix]?.end = endIndex
                self.fragment_by_end[endIndex] = f_ix
            }
        } else if let f_ix = self.fragment_by_start[endIndex] {
            if let g_ix = self.fragment_by_end[startIndex] {
                self.fragment_by_start.removeValue(forKey: endIndex)
                self.fragment_by_end.removeValue(forKey: startIndex)
                if f_ix == g_ix {
                    var f = self.f.pop(at: f_ix)!
                    f.ring.append(end)
                    result.append(f.ring)
                } else {
                    let f = self.f.pop(at: f_ix)!
                    var g = self.f.pop(at: g_ix)!
                    g.ring.append(contentsOf: f.ring);
                    let ix = self.f.put(item: Fragment(
                        start: g.start,
                        end: f.end,
                        ring: g.ring
                    ))
                    self.fragment_by_start[g.start] = ix
                    self.fragment_by_end[f.end] = ix
                }
            } else {
                self.fragment_by_start.removeValue(forKey: endIndex)
                f.inner[f_ix]?.ring.insert(start, at: 0)
                f.inner[f_ix]?.start = startIndex;
                self.fragment_by_start[startIndex] = f_ix
            }
        } else {
            let ix = self.f.put(item: Fragment(
                start: startIndex,
                end: endIndex,
                ring: [start, end]
            ))
            self.fragment_by_start[startIndex] = ix
            self.fragment_by_end[endIndex] = ix
        }
    }
    
    public mutating func clear() {
        self.f.clear()
        self.fragment_by_end.removeAll()
        self.fragment_by_start.removeAll()
        self.isEmpty = true;
    }
}

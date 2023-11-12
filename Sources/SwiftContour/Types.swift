//
//  Types.swift
//
//
//  Created by Matthew Iannucci on 11/11/23.
//

import Foundation
import GeoJSON

public struct Pt {
    public var x: Double
    public var y: Double
}

extension Position {
    init(pt: Pt) {
        self.init(longitude: pt.x, latitude: pt.y)
    }
}

public typealias Ring = [Pt]

extension LineString {
    init(ring: Ring) throws {
        try self.init(coordinates: ring.map({ Position(pt: $0 )}))
    }
}

extension Polygon.LinearRing {
    init(ring: Ring) throws {
        try self.init(coordinates: ring.map({ Position(pt: $0 )}))
    }
}

public struct Fragment {
    public var start: Int
    public var end: Int
    public var ring: Ring
}

public enum ContourError: Error {
    case dimensionError
}

public struct Slab<T> {
    var inner: [Int:T] = [:]
    private var counter = 0
    
    public func get(at index: Int) -> T? {
        return self.inner[index]
    }
    
    public mutating func put(item: T) -> Int {
        counter += 1
        inner[counter] = item
        return counter
    }
    
    public mutating func pop(at index: Int) -> T? {
        self.inner.removeValue(forKey: index)
    }
    
    public mutating func clear() {
        counter = 0
        inner.removeAll()
    }
}

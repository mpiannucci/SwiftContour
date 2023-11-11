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

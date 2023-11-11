import XCTest
@testable import SwiftContour

final class SwiftContourTests: XCTestCase {
    func testEmpty() throws {
        let builder = ContourBuilder(dx: 10, dy: 10, smooth: true, x_origin: 0.0, y_origin: 0.0, x_step: 1.0, y_step: 1.0)
        let data = [
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        ]
        
        let contours = try builder.contours(values: data, thresholds: [0.5])
        XCTAssert(contours.count == 1)
        switch contours[0].geometry {
        case .multiPolygon(let p): 
            XCTAssert(p.coordinates.count == 0)
            break
        default:
            break
        }
        
        let lines = try builder.lines(values: data, thresholds: [0.5])
        XCTAssert(lines.count == 1)
        switch lines[0].geometry {
        case .multiLineString(let l):
            XCTAssert(l.coordinates.count == 0)
            break
        default:
            break
        }
    }
    
    func testSimplePolygon() throws {
        let builder = ContourBuilder(dx: 10, dy: 10, smooth: true, x_origin: 0.0, y_origin: 0.0, x_step: 1.0, y_step: 1.0)
        let data = [
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
        ]
        
        let contours = try builder.contours(values: data, thresholds: [0.5])
        XCTAssert(contours.count == 1)
        guard case let .multiPolygon(polygons) = contours[0].geometry else {
            return
        }
        
        let coords = polygons.coordinates[0].coordinates[0].coordinates
        XCTAssert(coords.count == 17)
    }
}

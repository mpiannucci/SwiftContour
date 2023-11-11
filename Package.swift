// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftContour",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftContour",
            targets: ["SwiftContour"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kiliankoe/GeoJSON", .upToNextMajor(from: "0.6.2")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftContour",
            dependencies: [
                "GeoJSON"
            ]
        ),
        .testTarget(
            name: "SwiftContourTests",
            dependencies: ["SwiftContour"]),
    ]
)

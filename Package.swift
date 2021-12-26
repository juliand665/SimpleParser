// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "SimpleParser",
    products: [
        .library(
            name: "SimpleParser",
            targets: ["SimpleParser"]
		),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SimpleParser",
            dependencies: []
		),
        .testTarget(
            name: "SimpleParserTests",
            dependencies: ["SimpleParser"]
		),
    ]
)

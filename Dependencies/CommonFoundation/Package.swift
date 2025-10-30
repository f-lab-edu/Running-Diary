// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CommonFoundation",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "CommonFoundation",
            targets: ["CommonFoundation"]
        ),
    ],
    targets: [
        .target(
            name: "CommonFoundation"
        ),
        .testTarget(
            name: "CommonFoundationTests",
            dependencies: ["CommonFoundation"]
        ),
    ]
)

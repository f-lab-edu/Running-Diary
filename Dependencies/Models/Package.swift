// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Models",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "Models",
            targets: ["Models"]
        ),
    ],
    dependencies: [
        .package(path: "../CommonFoundation")
    ],
    targets: [
        .target(
            name: "Models",
            dependencies: ["CommonFoundation"]
        ),
        .testTarget(
            name: "ModelsTests",
            dependencies: ["Models"]
        ),
    ]
)

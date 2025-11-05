// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WeatherKitService",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "WeatherKitService",
            targets: ["WeatherKitService"]
        ),
    ],
    dependencies: [
        .package(path: "../Models")
    ],
    targets: [
        .target(
            name: "WeatherKitService",
            dependencies: ["Models"]
        ),
        .testTarget(
            name: "WeatherKitServiceTests",
            dependencies: ["WeatherKitService"]
        ),
    ]
)

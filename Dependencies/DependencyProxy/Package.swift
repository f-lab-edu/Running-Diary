// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DependencyProxy",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "DependencyProxy",
            targets: ["DependencyProxy"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/HorizonCalendar.git", branch: "master")
    ],
    targets: [
        .target(
            name: "DependencyProxy",
            dependencies: [
                .product(name: "HorizonCalendar", package: "HorizonCalendar")
            ]
        ),
        .testTarget(
            name: "DependencyProxyTests",
            dependencies: ["DependencyProxy"]
        ),
    ]
)

// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "GosenKit",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "GosenKit",
            targets: ["GosenKit"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "GosenKit",
            dependencies: []),
        .testTarget(
            name: "GosenKitTests",
            dependencies: ["GosenKit"]),
    ]
)

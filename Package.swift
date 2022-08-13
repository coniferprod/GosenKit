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
        .package(url: "https://github.com/coniferprod/SyxPack", from: "0.6.0"),
    ],
    targets: [
        .target(
            name: "GosenKit",
            dependencies: ["SyxPack"]),
        .testTarget(
            name: "GosenKitTests",
            dependencies: ["GosenKit", "SyxPack"],
            resources: [
                .copy("Resources")
            ]),
    ]
)

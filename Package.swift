// swift-tools-version:6.4

import PackageDescription

let package = Package(
    name: "GosenKit",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "GosenKit",
            targets: ["GosenKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/coniferprod/SyxPack", from: "0.9.0"),
        .package(url: "https://github.com/mesqueeb/CaseAnything", from: "0.1.8"),
        .package(url: "https://github.com/tadija/AEXML.git", from: "4.7.0"),
    ],
    targets: [
        .target(
            name: "GosenKit",
            dependencies: ["SyxPack", "CaseAnything", "AEXML"]),
        .testTarget(
            name: "GosenKitTests",
            dependencies: ["GosenKit", "SyxPack"]),
    ]
)

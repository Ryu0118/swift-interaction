// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-interaction",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .library(name: "Interaction", targets: ["Interaction"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.1.0"),
    ],
    targets: [
        .target(
            name: "Interaction",
            dependencies: [],
        ),
        .testTarget(
            name: "InteractionTests",
            dependencies: [
                "Interaction",
            ],
        ),
    ],
)

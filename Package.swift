// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mocap4face",
    platforms: [
            .iOS(.v13)
//          .macOS(.v10_14),
    ],
    products: [
        .library(
            name: "mocap4face",
            targets: ["Mocap4Face"]),
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
                    name: "Mocap4Face",
                    path: "frameworks/Mocap4Face.xcframework"
                )
    ]
)

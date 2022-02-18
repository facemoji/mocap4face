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
            targets: ["mocap4face"]),
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
                    name: "mocap4face",
                    path: "frameworks/Mocap4Face.xcframework"
                )
    ]
)
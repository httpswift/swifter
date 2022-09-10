// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwifterLite",
    products: [
        .library(
            name: "SwifterLite",
            targets: ["SwifterLite"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "SwifterLite",
            dependencies: [])
    ]
)

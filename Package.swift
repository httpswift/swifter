// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "Swifter",

  products: [
    .library(name: "Swifter", targets: ["Swifter"]),
    .executable(name: "Example", targets: ["Example"])
  ],

  dependencies: [],

  targets: [
    .target(name: "Swifter", dependencies: [], path: "Sources"),
    .target(name: "Example", dependencies: ["Swifter"], path: "Example"),
    .testTarget(name: "SwifterTests", dependencies: ["Swifter"], path: "XCode/Tests")
  ]
)
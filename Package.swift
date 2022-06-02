// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "Swifter",

  platforms: [.macOS(.v10_15)],

  products: [
    .library(name: "Swifter", targets: ["Swifter"]),
    .executable(name: "SwifterExample", targets: ["SwifterExample"])
  ],

  dependencies: [],

  targets: [
    .target(
      name: "Swifter", 
      dependencies: [], 
      path: "Xcode/Sources"
      ),

    .executableTarget(
      name: "SwifterExample",
      dependencies: [
        "Swifter"
      ], 
      path: "SwifterExample"
    ),

    .testTarget(
      name: "SwifterTests", 
      dependencies: [
        "Swifter"
      ], 
      path: "Xcode/Tests"
    )
  ]
)

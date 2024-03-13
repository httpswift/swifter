// swift-tools-version:5.3

import PackageDescription

let package = Package(
  name: "Swifter",

  products: [
    .library(name: "Swifter", targets: ["Swifter"]),
    .executable(name: "SwifterExample", targets: ["SwifterExample"])
  ],

  dependencies: [],

  targets: [
    .target(
      name: "Swifter",
      dependencies: [],
      path: "Xcode/Sources",
      resources: [
        .process("PrivacyInfo.xcprivacy")
      ]
      ),

    .target(
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

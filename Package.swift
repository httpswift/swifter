import PackageDescription

let package = Package(
    targets: [Target(name: "Swifter", dependencies: ["CSQLite"])]
)

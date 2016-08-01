import PackageDescription

let package = Package(
	name: "Swifter",
    targets: [Target(name: "Swifter", dependencies: ["CSQLite"])]
)

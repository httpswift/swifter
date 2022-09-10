![Platform](https://img.shields.io/badge/Platform-iOS%20macOS%20tvOS-4BC51D.svg?style=flat)
![Swift](https://img.shields.io/badge/Swift-5.1-4BC51D.svg?style=flat)
![Protocols](https://img.shields.io/badge/Protocols-HTTP%201.1-4BC51D.svg?style=flat)


### What is Swifter Lite?

Unofficial fork of Swifter written in [Swift](https://developer.apple.com/swift/) programming language, designed to be an embedded REST API server for iOS macOS and tvOS.

Supports data, json, text, bytes, audio and video streaming over HLS, over HTTP 1.1 protocol via http://localhost, ipv4 tcp/ip

Currently used in StarPlayrX and future IPTVee works by Todd Bruss

### Branches
`1.5.1`

#### To Do REST API examples to be expanded

### How to load HTML by string?
```swift
let server = HttpServer()
server[path] = { request in
    return HttpResponse.ok(.text("<html string>"))
}
server.start()
```

### Data Route
```swift
func dataRoute(_ data: Data) -> httpReq {{ request in
    return HttpResponse.ok(.data(data, contentType: "application/octet-stream"))
}}
```

### Swift Package Manager.
```swift
import PackageDescription

let package = Package(
    name: "YourServerName",
    products: [
        .library(
            name: "YourServerName",
            targets: ["YourServerName"]),
    ],
    dependencies: [
        .package(url: "https://github.com/StarPlayrX/Swifter-Lite", branch: "1.5.1")
    ],
    targets: [
        .target(
            name: "YourServerName",
            dependencies: [.product(name: "SwifterLite", package: "Swifter-Lite")]
        ),
    ]
)
```

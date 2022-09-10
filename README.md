![Platform](https://img.shields.io/badge/Platform-iOS%20&%20macOS%20&%20tvOS-4BC51D.svg?style=flat)
![Swift](https://img.shields.io/badge/Swift-5.1-4BC51D.svg?style=flat)
![Protocols](https://img.shields.io/badge/Protocols-HTTP%201.1%-4BC51D.svg?style=flat)


### What is Swifter Lite?

Unofficial fork of Swifter written in [Swift](https://developer.apple.com/swift/) programming language, designed to be an REST API embedded web server for iOS macOS and tvOS.

### Branches
`* 1.5.1-Lite`

### How to load HTML by string?
```swift
let server = HttpServer()
server[path] = { request in
    return HttpResponse.ok(.text("<html string>"))
}
server.start()
```

### Swift Package Manager.
```swift
import PackageDescription

let package = Package(
    name: "MyServer",
    dependencies: [
        .package(url: "https://github.com/StarPlayrX/Swifter-Lite.git", .upToNextMajor(from: "1.5.1"))
    ]
)
```

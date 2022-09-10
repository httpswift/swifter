![Platform](https://img.shields.io/badge/Platform-Linux%20&%20OSX%20&%20tvOS-4BC51D.svg?style=flat)
![Swift](https://img.shields.io/badge/Swift-4.x,_5.0-4BC51D.svg?style=flat)
![Protocols](https://img.shields.io/badge/Protocols-HTTP%201.1%20&%20WebSockets-4BC51D.svg?style=flat)
[![CocoaPods](https://img.shields.io/cocoapods/v/Swifter.svg?style=flat)](https://cocoapods.org/pods/Swifter)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

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

### What is Swift?

>Swift is an innovative new programming language for Cocoa and Cocoa Touch. Writing code is interactive and fun, the syntax is concise yet expressive, and apps run lightning-fast. Swift is ready for your next iOS and OS X project — or for addition into your current app — because Swift code works side-by-side with Objective-C.

### What is Swifter?

Tiny http server engine written in Swift ( https://developer.apple.com/swift/ ) programming language.

![Platform](https://img.shields.io/badge/Platform-Linux%20&%20OSX-4BC51D.svg?style=flat)
![Swift](https://img.shields.io/badge/Swift-2.2/3.0--dev-4BC51D.svg?style=flat)
![Protocols](https://img.shields.io/badge/Protocols-HTTP%201.1%20&%20WebSockets-4BC51D.svg?style=flat)
[![CocoaPods](https://img.shields.io/cocoapods/v/Swifter.svg?style=flat)]()
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

### How to start?
```swift
let server = HttpServer()
server["/hello"] = { .ok(.html("You asked for \($0)"))  }
server.start()
```
### How to share files?
```swift
let server = HttpServer()
server["/desktop/:path"] = shareFilesFromDirectory("/Users/me/Desktop")
server.start()
```
### How to redirect?
```swift
let server = HttpServer()
server["/redirect"] = { request in
  return .movedPermanently("http://www.google.com")
}
server.start()
```
### How to HTML ?
```swift
let server = HttpServer()
server["/my_html"] = scopes { 
  html {
    body {
      h1 { inner = "hello" }
    }
  }
}
server.start()
```
### How to WebSockets ?
```swift
let server = HttpServer()
server["/websocket-echo"] = websocket({ (session, text) in
  session.writeText(text)
}, { (session, binary) in
  session.writeBinary(binary)
})
server.start()
```
### CocoaPods? Yes.
```ruby
# Use version >= 1.1.0.rc.2 (sudo gem install cocoapods --pre)
use_frameworks!
pod 'Swifter', '~> 1.3.3'
```

### Carthage? Also yes.
```
# Use version >= 0.18 (https://github.com/Carthage/Carthage/releases/tag/0.18)
github "glock45/swifter" == 1.3.3
```

### Swift Package Manager.
```swift
import PackageDescription

let package = Package(
    name: "MyServer",
    dependencies: [
        .Package(url: "https://github.com/httpswift/swifter.git", majorVersion: 1)
    ]
)
```


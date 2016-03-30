![Logo](https://dl.dropboxusercontent.com/u/858551/httpswift_logo.png)

### What is Swifter?

Tiny http server engine written in Swift ( https://developer.apple.com/swift/ ) programming language.

![Platform](https://img.shields.io/badge/Platform-Linux%20&%20OSX-4BC51D.svg?style=flat)
![Swift](https://img.shields.io/badge/Swift-2.2/3.0--dev-4BC51D.svg?style=flat)
![Protocols](https://img.shields.io/badge/Protocols-HTTP%201.1%20&%20WebSockets-4BC51D.svg?style=flat)
[![CocoaPods](https://img.shields.io/cocoapods/v/Swifter.svg?style=flat)](https://github.com/CocoaPods/Specs/tree/c53b984dfc6dd421d8344c21225920a20e91373d/Specs/Swifter)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Slack](https://img.shields.io/badge/Slack-Join%20%23general-ff6666.svg?style=flat)](https://swifterteam.slack.com/messages/general/)

### How to start?
```swift
let server = HttpServer()
server["/hello"] = { .OK(.HTML("You asked for " + $0.url)) }
server.start()
```
### How to share files?
```swift
let server = HttpServer()
server["/desktop/:path"] = HttpHandlers.shareFilesFromDirectory("/Users/me/Desktop")
server.start()
```
### How to redirect?
```swift
let server = HttpServer()
server["/redirect"] = { request in
  return .MovedPermanently("http://www.google.com")
}
server.start()
```
### CocoaPods? Yes.
```
use_frameworks!
pod 'Swifter', '~> 1.1.3'
```

### Carthage? Also yes.

```
github "glock45/swifter" == 1.1.3
```

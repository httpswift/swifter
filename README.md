Swifter
=======

Tiny http server engine written in Swift ( https://developer.apple.com/swift/ ) programming language.

How to start ?
```swift
let server = HttpServer()
server["/hello"] = { .OK(.HTML("You asked for " + $0.url)) }
```
How to share files ? 
```swift
if let publicDir = publicDir {
    server["/home/(.+)"] = HttpHandlers.directory("~/")
}
```
How to redirect ?
```swift
server["/redirect"] = { request in
  return .MovedPermanently("http://www.google.com")
}
```



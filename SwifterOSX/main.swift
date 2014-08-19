//
//  main.swift
//  SwifterOSX
//
//  Created by Damian Kolakowski on 19/08/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

let server: HttpServer = HttpServer()

server["/resources/(.+)"] = "~/"

server["/test"] = { (method, url, headers) in
    var headersInfo = ""
    for (name, value) in headers {
        headersInfo += "\(name) : \(value)<br>"
    }
    let response = "<html><body>Url: \(url)<br>Method: \(method)<br>\(headersInfo)</body></html>"
    return .OK(.RAW(response))
}
server["/json"] = { (method, url, headers) in
    return .OK(.JSON(["posts" : [[ "id" : 1, "message" : "hello world"],[ "id" : 2, "message" : "sample message"]], "new_updates" : false]))
}
server["/redirect"] = { (method, url, headers) in
    return .MovedPermanently("http://www.google.com")
}
server["/long"] = { (method, url, headers) in
    var longResponse = ""
    for k in 0..<1000 { longResponse += "(\(k)),->" }
    return .OK(.RAW(longResponse))
}
server["/demo"] = { (method, url, headers) in
    return .OK(.RAW("<html><body><center><h2>Hello Swift</h2>" +
        "<img src=\"https://devimages.apple.com.edgekey.net/swift/images/swift-hero_2x.png\"/><br>" +
        "<h4>\(NSHost.currentHost().localizedName)</h4></center></body></html>"))
}
server["/"] = { (method, url, headers) in
    var listPage = "<html><body>Available services:<br><ul>"
    for item in server.routes() {
        listPage += "<li><a href=\"\(item)\">\(item)</a></li>"
    }
    listPage += "</ul></body></html>"
    return .OK(.RAW(listPage))
}

var error: NSError?

if !server.start(error: &error) {
    println("Server start error: \(error)")
} else {
    println("Server started !")
    while ( true ) { };
}




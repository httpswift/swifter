//
//  DemoServer.swift
//  Swifter
//
//  Created by Damian Kolakowski on 14/11/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

func demoServer(publicDir: String?) -> HttpServer {
    let server = HttpServer()
    if let publicDir = publicDir {
        server["/resources/(.+)"] = HttpHandlers.directory(publicDir)
    }
    server["/test"] = { request in
        var headersInfo = ""
        for (name, value) in request.headers {
            headersInfo += "\(name) : \(value)<br>"
        }
        let response = "<html><body>Url: \(request.url)<br>Method: \(request.method)<br>\(headersInfo)</body></html>"
        return .OK(.RAW(response))
    }
    server["/params/(.+)/(.+)"] = { request in
        var capturedGroups = ""
        for (index, group) in enumerate(request.capturedUrlGroups) {
            capturedGroups += "Expression group \(index) : \(group)<br>"
        }
        let response = "<html><body>Url: \(request.url)<br>Method: \(request.method)<br>\(capturedGroups)</body></html>"
        return .OK(.RAW(response))
    }
    server["/json"] = { request in
        return .OK(.JSON(["posts" : [[ "id" : 1, "message" : "hello world"],[ "id" : 2, "message" : "sample message"]], "new_updates" : false]))
    }
    server["/redirect"] = { request in
        return .MovedPermanently("http://www.google.com")
    }
    server["/long"] = { request in
        var longResponse = ""
        for k in 0..<1000 { longResponse += "(\(k)),->" }
        return .OK(.RAW(longResponse))
    }
    server["/demo"] = { request in
        return .OK(.RAW("<html><body><center><h2>Hello Swift</h2>" +
            "<img src=\"https://devimages.apple.com.edgekey.net/swift/images/swift-hero_2x.png\"/><br>" +
            "</center></body></html>"))
    }
    server["/"] = { request in
        var listPage = "<html><body>Available services:<br><ul>"
        for item in server.routes() {
            listPage += "<li><a href=\"\(item)\">\(item)</a></li>"
        }
        listPage += "</ul></body></html>"
        return .OK(.RAW(listPage))
    }
    return server
}
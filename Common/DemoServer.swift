//
//  DemoServer.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

func demoServer(publicDir: String?) -> HttpServer {
    let server = HttpServer()
    
    if let publicDir = publicDir {
        server["/resources/(.+)"] = HttpHandlers.directory(publicDir)
    }
    server["/files(.+)"] = HttpHandlers.directoryBrowser("~/")
    server["/magic"] = { .OK(.HTML("You asked for " + $0.url)) }
    server["/test"] = { request in
        var headersInfo = ""
        for (name, value) in request.headers {
            headersInfo += "\(name) : \(value)<br>"
        }
        var queryParamsInfo = ""
        for (name, value) in request.urlParams {
            queryParamsInfo += "\(name) : \(value)<br>"
        }
        return .OK(.HTML("<h3>Address: \(request.address)</h3><h3>Url:</h3> \(request.url)<h3>Method: \(request.method)</h3><h3>Headers:</h3>\(headersInfo)<h3>Query:</h3>\(queryParamsInfo)"))
    }
    server["/params/(.+)/(.+)"] = { request in
        var capturedGroups = ""
        for (index, group) in request.capturedUrlGroups.enumerate() {
            capturedGroups += "Expression group \(index) : \(group)<br>"
        }
        return .OK(.HTML("Url: \(request.url)<br>Method: \(request.method)<br>\(capturedGroups)"))
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
        return .OK(.HTML(longResponse))
    }
    server["/demo"] = { request in
        return .OK(.HTML("<center><h2>Hello Swift</h2>" +
            "<img src=\"https://devimages.apple.com.edgekey.net/swift/images/swift-hero_2x.png\"/><br>" +
            "</center>"))
    }
    server["/login"] = { request in
        switch request.method.uppercaseString {
            case "GET":
                if let rootDir = publicDir {
                    if let html = NSData(contentsOfFile:"\(rootDir)/login.html") {
                        return HttpResponse.RAW(200, "OK", nil, html)
                    } else {
                        return .NotFound
                    }
                }
                break;
            case "POST":
                if let body = request.body {
                    return .OK(.HTML(body))
                } else {
                    return .OK(.HTML("No POST params."))
            }
            default:
                return .NotFound
        }
        return .NotFound
    }
    server["/raw"] = { request in
        return HttpResponse.RAW(200, "OK", ["XXX-Custom-Header": "value"], "Sample Response".dataUsingEncoding(NSUTF8StringEncoding)!)
    }
    server["/"] = { request in
        var listPage = "Available services:<br><ul>"
        for item in server.routes() {
            listPage += "<li><a href=\"\(item)\">\(item)</a></li>"
        }
        listPage += "</ul>"
        return .OK(.HTML(listPage))
    }
    return server
}
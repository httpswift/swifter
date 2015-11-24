//
//  DemoServer.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public func demoServer(publicDir: String?) -> HttpServer {
    let server = HttpServer()
    
    if let publicDir = publicDir {
        server["/resources/(.+)"] = HttpHandlers.directory(publicDir)
    }
    
    server["/files(.+)"] = HttpHandlers.directoryBrowser("~/")
    server["/magic"] = { .OK(.Html("You asked for " + $0.url)) }
    
    server["/test"] = { request in
        var headersInfo = ""
        for (name, value) in request.headers {
            headersInfo += "\(name) : \(value)<br>"
        }
        var queryParamsInfo = ""
        for (name, value) in request.urlParams {
            queryParamsInfo += "\(name) : \(value)<br>"
        }
        return .OK(.Html("<h3>Address: \(request.address)</h3><h3>Url:</h3> \(request.url)<h3>Method: \(request.method)</h3><h3>Headers:</h3>\(headersInfo)<h3>Query:</h3>\(queryParamsInfo)"))
    }
    
    server["/params/(.+)/(.+)"] = { request in
        var capturedGroups = ""
        for (index, group) in request.capturedUrlGroups.enumerate() {
            capturedGroups += "Expression group \(index) : \(group)<br>"
        }
        return .OK(.Html("Url: \(request.url)<br>Method: \(request.method)<br>\(capturedGroups)"))
    }
    
    server["/json"] = { request in
        return .OK(.Json(["posts" : [[ "id" : 1, "message" : "hello world"],[ "id" : 2, "message" : "sample message"]], "new_updates" : false]))
    }
    
    server["/redirect"] = { request in
        return .MovedPermanently("http://www.google.com")
    }
    
    server["/long"] = { request in
        var longResponse = ""
        for k in 0..<1000 { longResponse += "(\(k)),->" }
        return .OK(.Html(longResponse))
    }
    
    server["/demo"] = { request in
        return .OK(.Html("<center><h2>Hello Swift</h2>" +
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
            case "POST":
                let formFields = request.parseForm()
                return HttpResponse.OK(.Html(formFields.map({ "\($0.0) = \($0.1)" }).joinWithSeparator("<br>")))
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
        listPage += server.routes.map({ "<li><a href=\"\($0)\">\($0)</a></li>"}).joinWithSeparator("")
        return .OK(.Html(listPage))
    }

    return server
}
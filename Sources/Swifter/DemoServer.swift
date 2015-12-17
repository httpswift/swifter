//
//  DemoServer.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public func demoServer(publicDir: String?) -> HttpServer {
    let server = HttpServer()
    
    if let publicDir = publicDir {
        server["/resources/:file"] = HttpHandlers.directory(publicDir)
    }
    
    server["/files/:path"] = HttpHandlers.directoryBrowser("~/")

    server["/"] = { r in
        var listPage = "Available services:<br><ul>"
        for route in server.routes {
            if route.method == nil || route.method! == .GET {
                listPage += "<li><a href=\"\(route.path)\">\(route.path)</a></li>"
            }
        }
        
        listPage += "</ul>"
        return .OK(.Html(listPage))
    }
    
    server["/magic"] = { .OK(.Html("You asked for " + $0.url)) }
    
    server["/test/:param1/:param2"] = { r in
        var headersInfo = ""
        for (name, value) in r.headers {
            headersInfo += "\(name) : \(value)<br>"
        }
        var queryParamsInfo = ""
        for (name, value) in r.urlParams {
            queryParamsInfo += "\(name) : \(value)<br>"
        }
        var pathParamsInfo = ""
        for token in r.params {
            pathParamsInfo += "\(token.0) : \(token.1)<br>"
        }
        return .OK(.Html("<h3>Address: \(r.address)</h3><h3>Url:</h3> \(r.url)<h3>Method: \(r.method)</h3><h3>Headers:</h3>\(headersInfo)<h3>Query:</h3>\(queryParamsInfo)<h3>Path params:</h3>\(pathParamsInfo)"))
    }
    
    server.GET["/upload"] = { r in
        if let rootDir = publicDir, html = NSData(contentsOfFile:"\(rootDir)/file.html") {
            var array = [UInt8](count: html.length, repeatedValue: 0)
            html.getBytes(&array, length: html.length)
            return HttpResponse.RAW(200, "OK", nil, array)
        }
        
        return .NotFound
    }
    
    server.POST["/upload"] = { r in
        let formFields = r.parseMultiPartFormData()
        return HttpResponse.OK(.Html(formFields.map({ UInt8ArrayToUTF8String($0.body) }).joinWithSeparator("<br>")))
    }
    
    server.GET["/login"] = { r in
        if let rootDir = publicDir, html = NSData(contentsOfFile:"\(rootDir)/login.html") {
                var array = [UInt8](count: html.length, repeatedValue: 0)
                html.getBytes(&array, length: html.length)
                return HttpResponse.RAW(200, "OK", nil, array)
        }
        
        return .NotFound
    }
    
    server.POST["/login"] = { r in
        let formFields = r.parseUrlencodedForm()
        return HttpResponse.OK(.Html(formFields.map({ "\($0.0) = \($0.1)" }).joinWithSeparator("<br>")))
    }
    
    server["/demo"] = { r in
        return .OK(.Html("<center><h2>Hello Swift</h2><img src=\"https://devimages.apple.com.edgekey.net/swift/images/swift-hero_2x.png\"/><br></center>"))
    }
    
    server["/raw"] = { request in
        return HttpResponse.RAW(200, "OK", ["XXX-Custom-Header": "value"], [UInt8]("Sample Response".utf8))
    }
    
    server["/json"] = { request in
        let jsonObject: NSDictionary = [NSString(string: "foo"): NSNumber(int: 3), NSString(string: "bar"): NSString(string: "baz")] 
        return .OK(.Json(jsonObject))
    }
    
    server["/redirect"] = { request in
        return .MovedPermanently("http://www.google.com")
    }

    server["/long"] = { request in
        var longResponse = ""
        for k in 0..<1000 { longResponse += "(\(k)),->" }
        return .OK(.Html(longResponse))
    }

    return server
}

//
//  DemoServer.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public func demoServer(publicDir: String) -> HttpServer {
    
    print(publicDir)
    
    let server = HttpServer()
    
    server["/public/:path"] = HttpHandlers.shareFilesFromDirectory(publicDir)
    
    server["/files/:path"] = HttpHandlers.directoryBrowser("/")

    server["/"] = { r in
        var listPage = "Available services:<br><ul>"
        for services in server.routes {
            if services.isEmpty {
                listPage += "<li><a href=\"/\">/</a></li>"
            } else {
                listPage += "<li><a href=\"\(services)\">\(services)</a></li>"
            }
        }
        listPage += "</ul>"
        return .OK(.Html(listPage))
    }
    
    server["/magic"] = { .OK(.Html("You asked for " + $0.path)) }
    
    server["/test/:param1/:param2"] = { r in
        var headersInfo = ""
        for (name, value) in r.headers {
            headersInfo += "\(name) : \(value)<br>"
        }
        var queryParamsInfo = ""
        for (name, value) in r.queryParams {
            queryParamsInfo += "\(name) : \(value)<br>"
        }
        var pathParamsInfo = ""
        for token in r.params {
            pathParamsInfo += "\(token.0) : \(token.1)<br>"
        }
        return .OK(.Html("<h3>Address: \(r.address)</h3><h3>Url:</h3> \(r.path)<h3>Method:</h3>\(r.method)<h3>Headers:</h3>\(headersInfo)<h3>Query:</h3>\(queryParamsInfo)<h3>Path params:</h3>\(pathParamsInfo)"))
    }
    
    server.GET["/upload"] = { r in
        if let html = NSData(contentsOfFile:"\(publicDir)/file.html") {
            var array = [UInt8](count: html.length, repeatedValue: 0)
            html.getBytes(&array, length: html.length)
            return HttpResponse.RAW(200, "OK", nil, { $0.write(array) })
        }
        return .NotFound
    }
    
    server.POST["/upload"] = { r in
        var response = ""
        for multipart in r.parseMultiPartFormData() {
            response += "Name: \(multipart.name) File name: \(multipart.fileName) Size: \(multipart.body.count)<br>"
        }
        return HttpResponse.OK(.Html(response))
    }
    
    server.GET["/login"] = { r in
        if let html = NSData(contentsOfFile:"\(publicDir)/login.html") {
            var array = [UInt8](count: html.length, repeatedValue: 0)
            html.getBytes(&array, length: html.length)
            return HttpResponse.RAW(200, "OK", nil, { $0.write(array) })
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
    
    server["/raw"] = { r in
        return HttpResponse.RAW(200, "OK", ["XXX-Custom-Header": "value"], { $0.write([UInt8]("test".utf8)) })
    }
    
    server["/json"] = { r in
        let jsonObject: NSDictionary = [NSString(string: "foo"): NSNumber(int: 3), NSString(string: "bar"): NSString(string: "baz")] 
        return .OK(.Json(jsonObject))
    }
    
    server["/redirect"] = { r in
        return .MovedPermanently("http://www.google.com")
    }

    server["/long"] = { r in
        var longResponse = ""
        for k in 0..<1000 { longResponse += "(\(k)),->" }
        return .OK(.Html(longResponse))
    }
    
    server["/wildcard/*/test/*/:param"] = { r in
        return .OK(.Html(r.path))
    }
    
    server["/stream"] = { r in
        return HttpResponse.RAW(200, "OK", nil, { w in
            for i in 0...100 {
                w.write([UInt8]("[chunk \(i)]".utf8));
            }
        })
    }
    
    server["/websocket-echo"] = HttpHandlers.websocket({ (session, text) in
        session.writeText(text)
    }, { (session, binary) in
        session.writeBinary(binary)
    })
    
    return server
}

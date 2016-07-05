//
//  DemoServer.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public func demoServer(_ publicDir: String) -> HttpServer {
    
    print(publicDir)
    
    let server = HttpServer()
    
    server["/public/:path"] = HttpHandlers.shareFilesFromDirectory(publicDir)

    server["/"] = HttpHandlers.scopes {
        html {
            body {
                ul(server.routes) { service in
                    li {
                        a { href = service; inner = service }
                    }
                }
            }
        }
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
            var array = [UInt8](repeating: 0, count: html.length)
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
            var array = [UInt8](repeating: 0, count: html.length)
            html.getBytes(&array, length: html.length)
            return HttpResponse.RAW(200, "OK", nil, { $0.write(array) })
        }
        return .NotFound
    }
    
    server.POST["/login"] = { r in
        let formFields = r.parseUrlencodedForm()
        return HttpResponse.OK(.Html(formFields.map({ "\($0.0) = \($0.1)" }).joined(separator: "<br>")))
    }
    
    server["/demo"] = HttpHandlers.scopes {
        html {
            body {
                center {
                    h2 { inner = "Hello Swift" }
                    img { src = "https://devimages.apple.com.edgekey.net/swift/images/swift-hero_2x.png" }
                }
            }
        }
    }
    
    server["/raw"] = { r in
        return HttpResponse.RAW(200, "OK", ["XXX-Custom-Header": "value"], { $0.write([UInt8]("test".utf8)) })
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
    
    server.get("/get-via-closure") { r in
        return .OK(.Html("GET OK"))
    }
    
    server.notFoundHandler = { r in
        return .MovedPermanently("https://github.com/404")
    }
    
    server.middleware.append({ r in
        print("\(r.method) - \(r.path)")
        return nil
    })
    
    server.GET["/scopes-demo"] = HttpHandlers.scopes {
        html {
            lang = "en"
            head {
                meta {
                    name = "Scopes DSL"
                    content = "Swift"
                }
                title {
                    inner = "Demo Web Page for Scopes DSL"
                }
                stylesheet {
                    href = "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css"
                }
            }
            body {
                table {
                    thead {
                        tr {
                            th { inner = "Number" }
                            th { inner = "Square" }
                        }
                    }
                    tbody(0..<1000) { i in
                        tr {
                            td { inner = "\(i)" }
                            td { inner = "\(i*i)" }
                        }
                    }
                }
            }
        }
    }
    
    return server
}

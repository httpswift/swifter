//
//  DemoServer.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

public func demoServer(publicDir: String) -> HttpServer {
    
    print(publicDir)
    
    let server = HttpServer()
    
    server["/public/:path"] = shareFilesFromDirectory(publicDir)
    server["/public/"] = shareFilesFromDirectory(publicDir)    // needed to serve index file at root level

    server["/files/:path"] = directoryBrowser("/")

    server["/"] = scopes {
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
        scopes {
            html {
                body {
                    h3 { inner = "Address: \(r.address)" }
                    h3 { inner = "Url: \(r.path)" }
                    h3 { inner = "Method: \(r.method)" }
                    
                    h3 { inner = "Query:" }
                    
                    table(r.queryParams) { param in
                        tr {
                            td { inner = param.0 }
                            td { inner = param.1 }
                        }
                    }
                    
                    h3 { inner = "Headers:" }
                    
                    table(r.headers) { header in
                        tr {
                            td { inner = header.0 }
                            td { inner = header.1 }
                        }
                    }
                    
                    h3 { inner = "Route params:" }
                    
                    table(r.params) { param in
                        tr {
                            td { inner = param.0 }
                            td { inner = param.1 }
                        }
                    }
                }
            }
        }(r)
    }
    
    server.GET["/upload"] = scopes {
        html {
            body {
                form {
                    method = "POST"
                    action = "/upload"
                    enctype = "multipart/form-data"
                    
                    input { name = "my_file1"; type = "file" }
                    input { name = "my_file2"; type = "file" }
                    input { name = "my_file3"; type = "file" }
                    
                    button {
                        type = "submit"
                        inner = "Upload"
                    }
                }
            }
        }
    }
    
    server.POST["/upload"] = { r in
        var response = ""
        for multipart in r.parseMultiPartFormData() {
            response += "Name: \(multipart.name) File name: \(multipart.fileName) Size: \(multipart.body.count)<br>"
        }
        return HttpResponse.OK(.Html(response))
    }
    
    server.GET["/login"] = scopes {
        html {
            head {
                script { src = "http://cdn.staticfile.org/jquery/2.1.4/jquery.min.js" }
                stylesheet { href = "http://cdn.staticfile.org/twitter-bootstrap/3.3.0/css/bootstrap.min.css" }
            }
            body {
                h3 { inner = "Sign In" }
                
                form {
                    method = "POST"
                    action = "/login"
                    
                    fieldset {
                        input { placeholder = "E-mail"; name = "email"; type = "email"; autofocus = "" }
                        input { placeholder = "Password"; name = "password"; type = "password"; autofocus = "" }
                        a {
                            href = "/login"
                            button {
                                type = "submit"
                                inner = "Login"
                            }
                        }
                    }
                    
                }
                javascript {
                    src = "http://cdn.staticfile.org/twitter-bootstrap/3.3.0/js/bootstrap.min.js"
                }
            }
        }
    }
    
    server.POST["/login"] = { r in
        let formFields = r.parseUrlencodedForm()
        return HttpResponse.OK(.Html(formFields.map({ "\($0.0) = \($0.1)" }).joinWithSeparator("<br>")))
    }
    
    server["/demo"] = scopes {
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
                w.write([UInt8]("[chunk \(i)]".utf8))
            }
        })
    }
    
    server["/websocket-echo"] = websocket({ (session, text) in
        session.writeText(text)
    }, { (session, binary) in
        session.writeBinary(binary)
    })
    
    server.notFoundHandler = { r in
        return .MovedPermanently("https://github.com/404")
    }
    
    server.middleware.append { r in
        print("Middleware:\(r.method) \(r.path)")
        return nil
    }
    
    return server
}
    

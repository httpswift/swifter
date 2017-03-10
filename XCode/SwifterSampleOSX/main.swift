//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
import Swifter


let server = try Swifter()

server.get("/") { _, request, responder in
    responder(html {
        "body" ~ {
            "h1" ~ "Hello World !"
        }
    })
}

server.get("/hello") { _, _, responder in
    responder(200)
}

server.get("/test/websocket") { _, request, responder in
    responder(WebsocketResponse(request) { event in
        switch event {
            case .text(let value):
                print("Got text message: \(value)")
            case .binary(let value):
                print("Got binary message: \(value)")
            case .disconnected(_, _):
                print("Peer disconneted")
        }
    })
}

server.get("/test/background") { _, _, closure in
    
    if #available(OSXApplicationExtension 10.10, *) {
        DispatchQueue.global(qos: .background).async {
            // Simulate http request to other service or a database query.
            sleep(2)
            closure(TextResponse(200, "Waited 2 secs for a response."))
        }
    } else {
        // Fallback on earlier versions
    }
    
}

server.get("/test/multipart") { _, request, responder in
    
    responder(html(200) {
        "body" ~ {
            "form(method=POST,action=/test/multipart,enctype=multipart/form-data)" ~ {

                "input(name=my_file1,type=file)" ~ ""
                "input(name=my_file2,type=file)" ~ ""
                "input(name=my_file3,type=file)" ~ ""

                "button(type=submit)" ~ "Upload"
            }
        }
    })
}

server.post("/test/multipart") { _, request, responder in
    
    let multiparts = request.parseMultiPartFormData()
    
    responder(html(200) {
        "body" ~ {
            "h5" ~ "Parts"
            "ul" ~ {
                multiparts.forEach { part in
                    "li" ~ "\(part.fileName) -- \(part.body.count)"
                }
            }
        }
    })
}

server.notFoundHandler = { r in
    return html(200) {
        "body" ~ {
            "h5" ~ "Page not found. Try:"
            "ul" ~ {
                server.routes.forEach { route in
                    "li" ~ {
                        "a(href=\(route))" ~ route
                    }
                }
            }
        }
    }
}

while true {
    try server.loop()
}



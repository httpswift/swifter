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

server.get("/stream") { _, request, responder in
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

server.get("/background") { _, _, closure in
    
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

server.post("/post") { _, request, responder in
    
    let post = request.parseUrlencodedForm()
    
    responder(html(200) {
        "body" ~ {
            "h4" ~ "You sent: "
            "ul" ~ {
                post.forEach { item in
                    "li" ~ "\(item.0) -> \(item.1)"
                }
            }
        }
    })
}

while true {
    try server.loop()
}



//
//  TestSocket.swift
//  Swifter
//
//  Created by Clément Nonn on 16/10/2015.
//  Copyright © 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
//http://socket.io/get-started/chat/
func testSocket(publicDir: String) -> HttpServer {
    let server = HttpServer()

    server["/resources/(.+)"] = HttpHandlers.directory(publicDir)
    
    server["/"] = { request in
        if let html = NSData(contentsOfFile:"\(publicDir)/index.html") {
            return HttpResponse.RAW(200, "OK", nil, html)
        } else {
            return .NotFound
        }
    }
    
    return server
}
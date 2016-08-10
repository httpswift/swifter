//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
import Swifter

let output: String = HMAC.sha1([UInt8]("key".utf8), [UInt8]("The quick brown fox jumps over the lazy dog".utf8))


do {
    let server: HttpServer = demoServer(try File.currentWorkingDirectory())
    server["/testAfterBaseRoute"] = { request in
        return .ok(.html("ok !"))
    }
    
    server["/lightroom"] = { r in
        
        print(String.fromUInt8(r.body))
        
        // JSON().encode()
        
        return .ok(.json(["result": "success"]))
    }
    
    if #available(OSX 10.10, *) {
        try server.start(9080)
    } else {
        // Fallback on earlier versions
    }
    print("Server has started ( port = 9080 ). Try to connect now...")
    RunLoop.main.run()
} catch {
    print("Server start error: \(error)")
}

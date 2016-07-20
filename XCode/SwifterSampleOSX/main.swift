//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
import Swifter

do {
    let server = demoServer(try File.currentWorkingDirectory())
    server["/testAfterBaseRoute"] = { request in
        return .OK(.Html("ok !"))
    }
    
    try server.start(9080, forceIPv4: true)
    print("Server has started ( port = \(server.port) ). Try to connect now...")
    
    NSRunLoop.mainRunLoop().run()
    
} catch {
    print("Server start error: \(error)")
}
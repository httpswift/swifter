//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
import Swifter

do {
    let server: HttpServer = demoServer(try File.currentWorkingDirectory())
    server["/testAfterBaseRoute"] = { request in
        return .OK(.Html("ok !"))
    }
    try server.start(9080)
    print("Server has started ( port = 9080 ). Try to connect now...")
    NSRunLoop.main().run()
} catch {
    print("Server start error: \(error)")
}
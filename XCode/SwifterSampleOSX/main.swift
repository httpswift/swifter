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
        return .ok(.html("ok !"))
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

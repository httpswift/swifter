//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
import Swifter

do {
    let server = demoServer(try String.File.currentWorkingDirectory())
    server["/testAfterBaseRoute"] = { request in
        return .ok(.html("ok !"))
    }
    
    if #available(OSXApplicationExtension 10.10, *) {
        try server.start(9080, forceIPv4: true)
    } else {
        // Fallback on earlier versions
    }
    
    print("Server has started ( port = \(try server.port()) ). Try to connect now...")
    
    RunLoop.main.run()
    
} catch {
    print("Server start error: \(error)")
}

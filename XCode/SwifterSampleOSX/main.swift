//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
import Swifter

do {
    let server = demoServer(try String.File.currentWorkingDirectory())
    let localserver = demoServer(try String.File.currentWorkingDirectory())
    server["/testAfterBaseRoute"] = { request in
        return .ok(.html("ok !"))
    }
    localserver["/testAfterBaseRoute"] = { request in
        return .ok(.html("ok !"))
    }

    let localpath = NSHomeDirectory() + "/.sampleSocket"

    if #available(OSXApplicationExtension 10.10, *) {
        try server.start(9080, forceIPv4: true)
        // The OS won't automatically delete this when the program ends, and it can't be reused
        if FileManager.default.fileExists(atPath: localpath) {
            try FileManager.default.removeItem(atPath: localpath)
        }
        try localserver.startLocal(localpath)
    } else {
        // Fallback on earlier versions
    }

    print("Server has started ( port = \(try server.port()) ). Try to connect now...")
    print("Local server has started ( path = \(try localserver.localPath()) ). Try connecting...")
    
    RunLoop.main.run()
    
} catch {
    print("Server start error: \(error)")
}

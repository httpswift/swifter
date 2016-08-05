//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
import Swifter


let encyrpted = RC4.encrypt([UInt8]("Plaintext".utf8), [UInt8]("Key".utf8))

print(encyrpted.map({ String(format: "%02x", $0) }).joined(separator: ","))

let deencyrpted = RC4.encrypt(encyrpted, [UInt8]("Key".utf8))

print(deencyrpted.map({ String(format: "%02x", $0) }).joined(separator: ","))

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

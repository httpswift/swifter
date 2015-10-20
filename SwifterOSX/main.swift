//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

let server = swiftyDemoServer(NSBundle.mainBundle().resourcePath!)

do {
    try server.start(9080)
    print("Server has started ( port = 9080 ). Try to connect now...")
    NSRunLoop.mainRunLoop().run()
} catch {
    print("Server start error: \(error)")
}
//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//


import Foundation

let server = demoServer(NSBundle.mainBundle().resourcePath)
do {
    try server.start(9080)
    print("Server started. Try a connection now...")
    NSRunLoop.mainRunLoop().run()
} catch {
    print("Server start error: \(error)")
}




//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//


import Foundation

var error: NSError?
let server = demoServer(NSBundle.mainBundle().resourcePath)

if !server.start(9080, error: &error) {
    print("Server start error: \(error)")
} else {
    print("Server started. Try a connection now...")
    NSRunLoop.mainRunLoop().run()
}




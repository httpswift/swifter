//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//


import Foundation

var error: NSError?
let server = demoServer(NSBundle.mainBundle().resourcePath)

if !server.start(listenPort: 9080, error: &error) {
    println("Server start error: \(error)")
} else {
    println("Server started; try a connection now")
    sleep(10)
    
    println("main thread is awake again")
    server.stop()
    
    println("Server started; try a connection now")
    sleep(10)
    
    server.start(listenPort: 9080, error: &error)
    
    println("stopped server; try to connect")
    while ( true ) { };
}




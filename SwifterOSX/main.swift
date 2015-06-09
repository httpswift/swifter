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
    println("Server started !")
    while ( true ) { };
}




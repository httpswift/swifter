//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

let DB = SQLiteActiveRecordProxy(name: "sample.db")

let scheme = DB.scheme()

let server = demoServer(NSBundle.mainBundle().resourcePath)

var error: NSError?

if !server.start(error: &error) {
    println("Server start error: \(error)")
} else {
    println("Server started !")
    while ( true ) { };
}




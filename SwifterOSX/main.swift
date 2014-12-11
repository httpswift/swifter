//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

let DB = SwifterSQLiteDatabaseProxy(name: "sample.db")

var error: NSError?

let scheme = DB.scheme(&error)

println(scheme)
println(error)

let server = demoServer(NSBundle.mainBundle().resourcePath)


if !server.start(error: &error) {
    println("Server start error: \(error)")
} else {
    println("Server started !")
    while ( true ) { };
}




//
//  main.swift
//  SwifterOSX
//
//  Created by Damian Kolakowski on 19/08/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

let server = demoServer("~/")

var error: NSError?

let person = Person()

if !server.start(error: &error) {
    println("Server start error: \(error)")
} else {
    println("Server started !")
    while ( true ) { };
}




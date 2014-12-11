//
//  ActiveRecordProxy.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

enum SwifterDatabseProxyType {
    case String, Integer, Float, Unknown
}

protocol SwifterDatabseProxy {
    func scheme(error: NSErrorPointer?) -> [String: [(String, String)]]?;
    
    func createTable(name: String, columns: [String: String], error: NSErrorPointer?) -> Bool;
    func deleteTable(name: String, error: NSErrorPointer?) -> Bool;
    
    func insertColumn(table: String, column: String, error: NSErrorPointer?) -> Bool;
    func deleteColumn(table: String, column: String, error: NSErrorPointer?) -> Bool;
    
    func copyColumn(table: String, from: String, to: String, error: NSErrorPointer?) -> Bool;
    
    func insertRow(table: String, value: [String: String], error: NSErrorPointer?) -> Int;
    func deleteRow(table: String, id: Int, error: NSErrorPointer?) -> Bool;
}
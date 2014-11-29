//
//  ActiveRecordProxy.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

enum ActiveRecordType {
    case String, Integer
}

protocol ActiveRecordProxy {
    func scheme() -> [String: [String: ActiveRecordType]];
    
    func createTable(name: String, columns: [String: ActiveRecordType], error: NSError) -> Bool;
    func deleteTable(name: String, error: NSError) -> Bool;
    
    func insertColumn(table: String, column: String, error: NSError) -> Bool;
    func deleteColumn(table: String, column: String, error: NSError) -> Bool;
    
    func copyColumn(table: String, from: String, to: String, error: NSError) -> Bool;
    
    func insertRow(table: String, value: [String: String], error: NSError) -> Int;
    func deleteRow(table: String, id: Int, error: NSError) -> Bool;
}
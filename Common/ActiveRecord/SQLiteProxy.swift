//
//  SQLiteProxy.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

class SQLiteActiveRecordProxy: ActiveRecordProxy {

    let databaseName: String

    init(name: String) {
        databaseName = name
    }
    
    func execute(statment: String, iteratorCallback: (COpaquePointer -> Void) ) -> Void {
        var databasePointer = COpaquePointer()
        if ( SQLITE_OK == databaseName.withCString { sqlite3_open($0, &databasePointer) } ) {
            var statmentPointer = COpaquePointer()
            if ( SQLITE_OK == statment.withCString { sqlite3_prepare(databasePointer, $0, Int32(strlen($0)), &statmentPointer, nil) } ) {
                while ( sqlite3_step(statmentPointer) == SQLITE_ROW ) { iteratorCallback(statmentPointer) }
                sqlite3_finalize(statmentPointer);
            }
            sqlite3_close(databasePointer);
        }
    }

    func scheme() -> [String: [String: ActiveRecordType]] {
        var tables = [String]()
        execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;") {
            let pointer = sqlite3_column_text($0, 0)
            if let name = String.fromCString(UnsafePointer<CChar>(COpaquePointer(pointer))) { tables.append(name) }
        }
        //TODO get columns
        var result = [String: [String: ActiveRecordType]]()
        return result
    }
    
    func createTable(name: String, columns: [String: ActiveRecordType], error: NSError) -> Bool {
        return false
    }
    
    func deleteTable(name: String, error: NSError) -> Bool {
        return false
    }
    
    func insertColumn(table: String, column: String, error: NSError) -> Bool {
        return false
    }
    
    func deleteColumn(table: String, column: String, error: NSError) -> Bool {
        return false
    }
    
    func copyColumn(table: String, from: String, to: String, error: NSError) -> Bool {
        return false
    }
    
    func insertRow(table: String, value: [String: String], error: NSError) -> Int {
        return 0
    }
    
    func deleteRow(table: String, id: Int, error: NSError) -> Bool {
        return false
    }
}
//
//  SQLiteProxy.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

class SQLiteSequenceElement {
    
    let statementPointer: COpaquePointer
    
    init(pointer: COpaquePointer) {
        self.statementPointer = pointer
    }
    
    func string(column: Int32) -> String {
        if let value = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statementPointer, column))) {
            return value
        }
        /// Should never happend :)
        /// From 'String.fromCString' documentation:
        /// Returns `nil` if the `CString` is `NULL` or if it contains ill-formed
        /// UTF-8 code unit sequences.
        return "????"
    }
    
    func integer(column: Int32) -> Int32 {
        return sqlite3_column_int(statementPointer, column)
    }
    
    func double(column: Int32) -> Double {
        return sqlite3_column_double(statementPointer, column)
    }
}

class SQLiteSequenceGenarator: GeneratorType {
    
    let statementPointer: COpaquePointer
    
    init(pointer: COpaquePointer) {
        self.statementPointer = pointer
    }
    
    func next() -> SQLiteSequenceElement? {
        if ( sqlite3_step(statementPointer) == SQLITE_ROW ) {
            return SQLiteSequenceElement(pointer: statementPointer)
        }
        sqlite3_finalize(statementPointer)
        return nil
    }
}

class SQLiteSequence: SequenceType {
    
    var statementPointer = COpaquePointer()
    
    init?(db: COpaquePointer, sql: String, err: NSErrorPointer? = nil) {
        let result = sql.withCString { sqlite3_prepare(db, $0, Int32(strlen($0)), &self.statementPointer, nil) };
        if result != SQLITE_OK {
            if let err = err { err.memory = error("Can't prepare statement: \(sql), Error: \(result)") }
            return nil
        }
    }
    
    func error(reason: String) -> NSError {
        return NSError(domain: "SQLiteSequence", code: 0, userInfo: [NSLocalizedDescriptionKey : reason])
    }
    
    func generate() -> SQLiteSequenceGenarator {
        return SQLiteSequenceGenarator(pointer: statementPointer)
    }
}

class SwifterSQLiteDatabaseProxy: SwifterDatabseProxy {

    let name: String
    
    init(name databaseName: String) {
        name = databaseName
    }
    
    func err(reason: String) -> NSError {
        return NSError(domain: "SwifterSQLiteDatabaseProxy", code: 0, userInfo: [NSLocalizedDescriptionKey : reason])
    }
    
    func execute<Result>(name: String, sql: String, err: NSErrorPointer? = nil, f: ((SQLiteSequence) -> Result?)? = nil ) -> Result? {
        var database = COpaquePointer()
        if ( SQLITE_OK == name.withCString { sqlite3_open($0, &database) } ) {
            if let sequence = SQLiteSequence(db: database, sql: sql, err: err) {
                var result: Result?
                if let f = f {
                    result = f(sequence)
                }
                sqlite3_close(database)
                return result
            }
            sqlite3_close(database)
        }
        return nil
    }
    
    func scheme(error: NSErrorPointer?) -> [String: [(String, String)]]? {
        let tables: [String]? = execute(name, sql: "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;", err: error) { map($0, { $0.string(0) }) }
        if let tables = tables {
            var scheme = [String: [(String, String)]]()
            for table in tables {
                let columns: [(String, String)]? = execute(name, sql: "PRAGMA table_info('\(table)');", err: error) { map($0, { ($0.string(1), $0.string(2)) } ) }
                if let columns = columns {
                    scheme[table] = columns
                } else {
                    return nil
                }
            }
            return scheme
        }
        return nil
    }
    
    func createTable(name: String, columns: [String: String], error: NSErrorPointer?) -> Bool {
        return false
    }
    
    func deleteTable(name: String, error: NSErrorPointer?) -> Bool {
        return false
    }
    
    func insertColumn(table: String, column: String, error: NSErrorPointer?) -> Bool {
        return false
    }
    
    func deleteColumn(table: String, column: String, error: NSErrorPointer?) -> Bool {
        return false
    }
    
    func copyColumn(table: String, from: String, to: String, error: NSErrorPointer?) -> Bool {
        return false
    }
    
    func insertRow(table: String, value: [String: String], error: NSErrorPointer?) -> Int {
        return 0
    }
    
    func deleteRow(table: String, id: Int, error: NSErrorPointer?) -> Bool {
        return false
    }
}
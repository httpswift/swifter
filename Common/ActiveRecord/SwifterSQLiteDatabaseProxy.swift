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
    
    func integer(column: Int32) -> Double {
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
    
    init?(database: COpaquePointer, statement: String, error: NSErrorPointer? = nil) {
        let result = statement.withCString { sqlite3_prepare(database, $0, Int32(strlen($0)), &self.statementPointer, nil) };
        if result != SQLITE_OK {
            if let error = error { error.memory = err("Can't prepare statement: \(statement), Error: \(result)") }
            return nil
        }
    }
    
    func err(reason: String) -> NSError {
        return NSError(domain: "SQLiteSequence", code: 0, userInfo: [NSLocalizedDescriptionKey : reason])
    }
    
    func generate() -> SQLiteSequenceGenarator {
        return SQLiteSequenceGenarator(pointer: statementPointer)
    }
}

class SQLiteStatement: StringLiteralConvertible {
    
    typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    typealias UnicodeScalarLiteralType = UnicodeScalarType
    
    let sqlStatement: String
    
    init(value: String) {
        self.sqlStatement = value
    }
    
    required init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.sqlStatement = value
    }
    
    required init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.sqlStatement = value
    }
    
    required init(stringLiteral value: StringLiteralType) {
        self.sqlStatement = value
    }
    
    func execute(databse: COpaquePointer, error: NSErrorPointer? = nil) -> SQLiteSequence? {
        return SQLiteSequence(database: databse, statement: sqlStatement, error: error)
    }
}

class SwifterSQLiteDatabaseProxy: SwifterDatabseProxy {

    let databaseName: String
    let typesMap = [ "TEXT": SwifterDatabseProxyType.String, "INT": .Integer, "REAL": .Float]
    
    init(name: String) {
        databaseName = name
    }
    
    func err(reason: String) -> NSError {
        return NSError(domain: "SwifterSQLiteDatabaseProxy", code: 0, userInfo: [NSLocalizedDescriptionKey : reason])
    }
    
    func scheme(error: NSErrorPointer?) -> [String: [(String, SwifterDatabseProxyType)]]? {
        var database = COpaquePointer()
        if ( SQLITE_OK != databaseName.withCString { sqlite3_open($0, &database) } ) {
            if let e = error { e.memory = err("Cant' open databse: \(databaseName)") }
            return nil
        }
        var scheme = [String: [(String, SwifterDatabseProxyType)]]()
        let tablesQuery: SQLiteStatement = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;";
        if let tables = tablesQuery.execute(database, error: error) {
            for table in map(tables, { $0.string(0) }) {
                if let columns = SQLiteStatement(value: "PRAGMA table_info('\(table)');").execute(database, error: error) {
                    scheme[table] = map(columns) {
                        if let swifterType = self.typesMap[$0.string(2)] { return ($0.string(1), swifterType) }
                        return ($0.string(1), SwifterDatabseProxyType.Unknown)
                    }
                }
            }
            sqlite3_close(database)
            return scheme
        } else {
            sqlite3_close(database)
            if let e = error { e.memory = err("Cant' query tables databse: \(tablesQuery)") }
            return nil
        }
    }
    
    func createTable(name: String, columns: [String: SwifterDatabseProxyType], error: NSErrorPointer?) -> Bool {
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
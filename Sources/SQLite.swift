//
//  SQLite.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public enum SQLiteError: ErrorType {
    case OpenFailed(String?)
    case ExecFailed(String?)
}

public class SQLite {
    
    private let databaseConnection: COpaquePointer
    
    public static func open(path: String) throws -> SQLite {
        var databaseConnection = COpaquePointer()
        let openResult = path.withCString { sqlite3_open($0, &databaseConnection) }
        guard openResult == SQLITE_OK else {
            throw SQLiteError.OpenFailed(String.fromCString(sqlite3_errmsg(databaseConnection)))
        }
        return SQLite(databaseConnection)
    }
    
    private init(_ databaseConnection: COpaquePointer) {
        self.databaseConnection = databaseConnection
    }
    
    private struct ExecCContext { var callback: ([String: String] -> Void)? }

    public func exec(sql: String) throws {
        try exec(sql, nil)
    }
    
    public func exec(sql: String, _ stepCallback: ([String: String] -> Void)?) throws {
        var errorMessagePointer = UnsafeMutablePointer<Int8>()
        var execCContext = ExecCContext(callback: stepCallback)
        let execResult = sql.withCString {
            sqlite3_exec(databaseConnection, $0, { (context, count, values, names) -> Int32 in
                var content = [String: String]()
                for i in 0..<count {
                    if let name = String.fromCString(names.advancedBy(Int(i)).memory),
                        let value = String.fromCString(values.advancedBy(Int(i)).memory) {
                            content[name] = value
                    }
                }
                if let callback = UnsafeMutablePointer<ExecCContext>(context).memory.callback {
                    callback(content)
                }
                return SQLITE_OK
            }, &execCContext, &errorMessagePointer)
        }
        guard execResult == SQLITE_OK else {
            let errorDetails = String.fromCString(errorMessagePointer)
            sqlite3_free(errorMessagePointer)
            throw SQLiteError.ExecFailed(errorDetails)
        }
    }
    
    public func enumerate(sql: String) throws -> StatmentSequence {
        var statement = COpaquePointer()
        let prepareResult = sql.withCString { sqlite3_prepare_v2(databaseConnection, $0, Int32(sql.utf8.count), &statement, nil) }
        guard prepareResult == SQLITE_OK else {
            throw SQLiteError.ExecFailed(String.fromCString(sqlite3_errmsg(databaseConnection)))
        }
        return StatmentSequence(statement: statement)
    }
    
    public struct StatmentGenerator: GeneratorType {
        
        public let statement: COpaquePointer
        
        public func next() -> [String: String]? {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                var content = [String: String]()
                for i in 0..<sqlite3_column_count(statement) {
                    if let name = String.fromCString(UnsafePointer<CChar>(sqlite3_column_name(statement, i))),
                        let value = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(statement, i))) {
                            content[name] = value
                    }
                }
                return content
            default:
                sqlite3_finalize(statement)
                return nil
            }
        }
    }
    
    public struct StatmentSequence: SequenceType {
        
        public let statement: COpaquePointer
        
        public func generate() -> StatmentGenerator {
            return StatmentGenerator(statement: statement)
        }
    }
    
    public func close() {
        sqlite3_close(databaseConnection)
    }
}

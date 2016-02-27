//
//  SQLite.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

enum SQLiteError: ErrorType {
    case OpenFailed(String?)
    case ExecFailed(String?)
}

public class SQLite {
    
    private let internalPointer: COpaquePointer
    
    public static func open(path: String) throws -> SQLite {
        var sqlite3DatabasePointer = COpaquePointer()
        let openResult = path.withCString { sqlite3_open($0, &sqlite3DatabasePointer) }
        guard openResult == SQLITE_OK else {
            throw SQLiteError.OpenFailed(String.fromCString(sqlite3_errmsg(sqlite3DatabasePointer)))
        }
        return SQLite(sqlite3DatabasePointer)
    }
    
    private init(_ pointer: COpaquePointer) {
        self.internalPointer = pointer
    }
    
    private struct ExecCContext { var callback: ([String: String] -> Void)? }

    public func exec(sql: String) throws {
        try exec(sql, callback: nil)
    }
    
    public func exec(sql: String, callback: ([String: String] -> Void)?) throws {
        var errorMessagePointer = UnsafeMutablePointer<Int8>()
        var execCContext = ExecCContext(callback: callback)
        let execResult = sql.withCString {
            sqlite3_exec(internalPointer, $0, { (context, count, values, names) -> Int32 in
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
    
    public func close() throws {
        sqlite3_close(internalPointer)
    }
}

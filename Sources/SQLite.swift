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
    case BindFailed(String?)
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
    
    public func exec(sql: String, _ params: [String?]? = nil, _ step: ([String: String?] -> Void)? = nil) throws {
        var statement = COpaquePointer()
        let prepareResult = sql.withCString { sqlite3_prepare_v2(databaseConnection, $0, Int32(sql.utf8.count), &statement, nil) }
        guard prepareResult == SQLITE_OK else {
            throw SQLiteError.ExecFailed(String.fromCString(sqlite3_errmsg(databaseConnection)))
        }
        for (index, value) in (params ?? [String?]()).enumerate() {
            let bindResult = value?.withCString({ sqlite3_bind_text(statement, index + 1, $0, -1 /* take zero terminator. */) { _ in } })
                    ?? sqlite3_bind_null(statement, index + 1)
            guard bindResult == SQLITE_OK else {
                throw SQLiteError.BindFailed(String.fromCString(sqlite3_errmsg(databaseConnection)))
            }
        }
        while true {
            let stepResult = sqlite3_step(statement)
            switch stepResult {
            case SQLITE_ROW:
                var content = [String: String?]()
                for i in 0..<sqlite3_column_count(statement) {
                    if let name = String.fromCString(UnsafePointer<CChar>(sqlite3_column_name(statement, i))) {
                        let pointer = sqlite3_column_text(statement, i)
                        if pointer == nil {
                            content[name] = nil
                        } else {
                            content[name] = String.fromCString(UnsafePointer<CChar>(pointer))
                        }
                    }
                }
                step?(content)
            case SQLITE_DONE:
                return
            case SQLITE_ERROR:
                throw SQLiteError.ExecFailed("sqlite3_step() returned SQLITE_ERROR.")
            default:
                throw SQLiteError.ExecFailed("Unknown result for sqlite3_step(): \(stepResult)")
            }
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
                    if let name = String.fromCString(UnsafePointer<CChar>(sqlite3_column_name(statement, i))) {
                        let pointer = sqlite3_column_text(statement, i)
                        if pointer == nil {
                            content[name] = nil
                        } else {
                            content[name] = String.fromCString(UnsafePointer<CChar>(pointer))
                        }
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

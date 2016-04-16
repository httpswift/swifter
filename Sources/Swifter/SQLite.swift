//
//  SQLite.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation
import CSQLite

public enum SQLiteError: ErrorProtocol {
    case OpenFailed(String?)
    case ExecFailed(String?)
    case BindFailed(String?)
}

public class SQLite {
    
    private let databaseConnection: OpaquePointer
    
    public static func open(_ path: String) throws -> SQLite {
        var databaseConnectionPointer: OpaquePointer? = nil
        let openResult = path.withCString { sqlite3_open($0, &databaseConnectionPointer) }
        guard let databaseConnection = databaseConnectionPointer else {
            throw SQLiteError.ExecFailed("Invalid pointer.")
        }
        guard openResult == SQLITE_OK else {
            throw SQLiteError.OpenFailed(String(cString: sqlite3_errmsg(databaseConnection)))
        }
        return SQLite(databaseConnection)
    }
    
    private init(_ databaseConnection: OpaquePointer) {
        self.databaseConnection = databaseConnection
    }
    
    public func exec(_ sql: String) throws {
        try exec(sql, nil)
    }
    
    public func exec(_ sql: String, _ params: [String?]? = nil, _ step: ([String: String?] -> Void)? = nil) throws {
        var statementPointer: OpaquePointer? = nil
        let prepareResult = sql.withCString { sqlite3_prepare_v2(databaseConnection, $0, Int32(sql.utf8.count), &statementPointer, nil) }
        guard prepareResult == SQLITE_OK else {
            throw SQLiteError.ExecFailed(String(cString: sqlite3_errmsg(databaseConnection)))
        }
        guard let statement = statementPointer else {
            throw SQLiteError.ExecFailed("Invalid pointer.")
        }
        for (index, value) in (params ?? [String?]()).enumerated() {
            let bindResult = value?.withCString({ sqlite3_bind_text(statement, index + 1, $0, -1 /* take zero terminator. */) { _ in } })
                    ?? sqlite3_bind_null(statement, index + 1)
            guard bindResult == SQLITE_OK else {
                throw SQLiteError.BindFailed(String(cString: sqlite3_errmsg(databaseConnection)))
            }
        }
        while true {
            let stepResult = sqlite3_step(statement)
            switch stepResult {
            case SQLITE_ROW:
                var content = [String: String?]()
                for i in 0..<sqlite3_column_count(statement) {
                    let name = String(cString: UnsafePointer<CChar>(sqlite3_column_name(statement, i)))
                    let pointer = sqlite3_column_text(statement, i)
                    if pointer == nil {
                        content[name] = nil
                    } else {
                        content[name] = String(cString: UnsafePointer<CChar>(pointer))
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
    
    
    public func enumerate(_ sql: String) throws -> StatmentSequence {
        var statement: OpaquePointer? = nil
        let prepareResult = sql.withCString { sqlite3_prepare_v2(databaseConnection, $0, Int32(sql.utf8.count), &statement, nil) }
        guard prepareResult == SQLITE_OK else {
            throw SQLiteError.ExecFailed(String(cString: sqlite3_errmsg(databaseConnection)))
        }
        guard let readyStatement = statement else {
            throw SQLiteError.ExecFailed("Invalid pointer.")
        }
        return StatmentSequence(statement: readyStatement)
    }
    
    public struct StatmentGenerator: IteratorProtocol {
        
        public let statement: OpaquePointer
        
        public func next() -> [String: String]? {
            switch sqlite3_step(statement) {
            case SQLITE_ROW:
                var content = [String: String]()
                for i in 0..<sqlite3_column_count(statement) {
                    let name = String(cString: UnsafePointer<CChar>(sqlite3_column_name(statement, i)))
                    let pointer = sqlite3_column_text(statement, i)
                    if pointer == nil {
                        content[name] = nil
                    } else {
                        content[name] = String(cString: UnsafePointer<CChar>(pointer))
                    }
                }
                return content
            default:
                sqlite3_finalize(statement)
                return nil
            }
        }
    }
    
    public struct StatmentSequence: Sequence {
        
        public let statement: OpaquePointer
        
        public func makeIterator() -> StatmentGenerator {
            return StatmentGenerator(statement: statement)
        }
    }
    
    public func close() {
        sqlite3_close(databaseConnection)
    }
}

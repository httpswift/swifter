//
//  SQLite.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation
import CSQLite

public enum SQLiteError: Error {
    case openFailed(String?)
    case execFailed(String?)
    case bindFailed(String?)
}

public class SQLite {
    
    private let databaseConnection: OpaquePointer
    
    public static func open(_ path: String) throws -> SQLite {
        var databaseConnectionPointer: OpaquePointer? = nil
        let openResult = path.withCString { sqlite3_open($0, &databaseConnectionPointer) }
        guard let databaseConnection = databaseConnectionPointer else {
            throw SQLiteError.execFailed("Invalid pointer.")
        }
        guard openResult == SQLITE_OK else {
            throw SQLiteError.openFailed(String(cString: sqlite3_errmsg(databaseConnection)))
        }
        return SQLite(databaseConnection)
    }
    
    private init(_ databaseConnection: OpaquePointer) {
        self.databaseConnection = databaseConnection
    }
    
    public func exec(_ sql: String) throws {
        try exec(sql, nil)
    }
    
    public func exec(_ sql: String, _ params: [String?]? = nil, _ step: (([String: String?]) -> Void)? = nil) throws {
        var statementPointer: OpaquePointer? = nil
        let prepareResult = sql.withCString { sqlite3_prepare_v2(databaseConnection, $0, Int32(sql.utf8.count), &statementPointer, nil) }
        guard prepareResult == SQLITE_OK else {
            throw SQLiteError.execFailed(String(cString: sqlite3_errmsg(databaseConnection)))
        }
        guard let statement = statementPointer else {
            throw SQLiteError.execFailed("Invalid pointer.")
        }
        for (index, value) in (params ?? [String?]()).enumerated() {
            let bindResult = value?.withCString({ sqlite3_bind_text(statement, index + 1, $0, -1 /* take zero terminator. */) { _ in } })
                    ?? sqlite3_bind_null(statement, index + 1)
            guard bindResult == SQLITE_OK else {
                throw SQLiteError.bindFailed(String(cString: sqlite3_errmsg(databaseConnection)))
            }
        }
        while true {
            let stepResult = sqlite3_step(statement)
            switch stepResult {
            case SQLITE_ROW:
                var content = [String: String?]()
                for i in 0..<sqlite3_column_count(statement) {
                    let name = String(cString: UnsafePointer<CChar>(sqlite3_column_name(statement, i)))
                    if let pointer = sqlite3_column_text(statement, i) {
                        content[name] = String(cString: UnsafePointer<CChar>(pointer))
                    } else {
                        content[name] = nil
                    }
                }
                step?(content)
            case SQLITE_DONE:
                return
            case SQLITE_ERROR:
                throw SQLiteError.execFailed("sqlite3_step() returned SQLITE_ERROR.")
            default:
                throw SQLiteError.execFailed("Unknown result for sqlite3_step(): \(stepResult)")
            }
        }
    }
    
    
    public func enumerate(_ sql: String) throws -> StatmentSequence {
        var statement: OpaquePointer? = nil
        let prepareResult = sql.withCString { sqlite3_prepare_v2(databaseConnection, $0, Int32(sql.utf8.count), &statement, nil) }
        guard prepareResult == SQLITE_OK else {
            throw SQLiteError.execFailed(String(cString: sqlite3_errmsg(databaseConnection)))
        }
        guard let readyStatement = statement else {
            throw SQLiteError.execFailed("Invalid pointer.")
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
                    if let pointer = sqlite3_column_text(statement, i) {
                        content[name] = String(cString: UnsafePointer<CChar>(pointer))
                    } else {
                        content[name] = nil
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

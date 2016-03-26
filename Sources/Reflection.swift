//
//  Relfection.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public protocol DatabaseReflectionProtocol {
    
    var id: UInt64? { get }
    
    init()
}

public class DatabaseReflection: DatabaseReflectionProtocol {
    
    static var sharedDatabase: SQLite?
    
    public var id: UInt64? = nil
    
    required public init() { }
}

public extension DatabaseReflectionProtocol {
    
    public func schemeWithValuesMethod1() -> (String, [String: Any?]) {
        let reflections = _reflect(self)
        
        var fields = [String: Any?]()
        for index in stride(from: 0, to: reflections.count, by: 1) {
            let reflection = reflections[index]
            fields[reflection.0] = reflection.1.value
        }
        
        return (reflections.summary, fields)
    }
    
    public func schemeWithValuesMethod2() -> (String, [String: Any?]) {
        let mirror = Mirror(reflecting: self)
        
        var fields = [String: Any?]()
        for case let (label?, value) in mirror.children {
            fields[label] = value
        }
        
        return ("\(mirror.subjectType)", fields)
    }
    
    public func schemeWithValuesAsString() -> (String, [(String, String?)]) {
        let (name, fields) = schemeWithValuesMethod2()
        let (_, _) = schemeWithValuesMethod1()
        var map = [(String, String?)]()
        for (key, value) in fields {
            // TODO - Replace this by extending all supported types by a protocol.
            // Example: 'extenstion Int: DatabaseConvertible { convert() -> something ( not necessary String type ) }'
            if let intValue    = value as? Int    { map.append((key, String(intValue))) }
            if let int32Value  = value as? Int32  { map.append((key, String(int32Value))) }
            if let int64Value  = value as? Int64  { map.append((key, String(int64Value))) }
            if let doubleValue = value as? Double { map.append((key, String(doubleValue))) }
            if let stringValue = value as? String { map.append((key, stringValue)) }
        }
        return (name, map)
    }
    
    public static func classInstanceWithSchemeMethod1() -> (Self, String, [String: Any?]) {
        let instance = Self()
        let (name, fields) = instance.schemeWithValuesMethod1()
        return (instance, name, fields)
    }
    
    public static func classInstanceWithSchemeMethod2() -> (Self, String, [String: Any?]) {
        let instance = Self()
        let (name, fields) = instance.schemeWithValuesMethod2()
        return (instance, name, fields)
    }
    
    static func find(id: UInt64) -> Self? {
        let (instance, _, _) = classInstanceWithSchemeMethod1()
        // TODO - make a query to DB
        return instance
    }
    
    public func insert() throws {
        guard let database = DatabaseReflection.sharedDatabase else {
            throw SQLiteError.OpenFailed("Database connection is not opened.")
        }
        let (name, fields) = schemeWithValuesAsString()
        try database.exec("CREATE TABLE IF NOT EXISTS \(name) (" + fields.map { "\($0.0) TEXT" }.joined(separator: ", ")  + ");")
        let names = fields.map { "\($0.0)" }.joined(separator: ", ")
        let values = Array(repeating: "?", count: fields.count).joined(separator: ", ")
        try database.exec("INSERT INTO \(name)(" + names + ") VALUES(" + values  + ");", fields.map { $0.1 })
    }
    
}
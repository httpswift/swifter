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
    
    public var id: UInt64? = nil
    
    required public init() { }
    
}

public extension DatabaseReflectionProtocol {
    
    public func schemeWithValuesMethod1() -> (String, [String: Any?]) {
        let reflections = _reflect(self)
        
        var fields = [String: Any?]()
        for index in 0.stride(to: reflections.count, by: 1) {
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
    
    func insert() throws {
        // Stub.
    }
    
    func update() throws {
        // Stub.
    }
    
}
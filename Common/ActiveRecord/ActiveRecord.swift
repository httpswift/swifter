//
//  ActiveRecord.swift
//  Swifter
//
//  Created by Damian Kolakowski on 13/11/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

struct SwifterActiveRecordField {
    let name: String?
}

class SwifterActiveRecord<T: NSObject> {
    
    init() {
        let properties = scheme()
    }
    
    private func scheme() -> [SwifterActiveRecordField] {
        var results = [SwifterActiveRecordField]()
        let classInfoDump = reflect(self)
        for var index = 1; index < classInfoDump.count; ++index {
            let field = classInfoDump[index]
            results.append(SwifterActiveRecordField(name: field.0))
        }
        return results
    }
    
    class func find(T -> Bool) -> [T] {
        return []
    }
    
    class func all() -> Array<String> {
        return []
    }
    
    func commit(error: NSErrorPointer) -> Bool {
        return false
    }
}

// An example model class.

class Person: NSObject {
    var firstName: String? = "firstName"
    var lastName: String? = "lastName"
    var age: UInt? = 1
}

let peopleWithNameFoo = SwifterActiveRecord<Person>.find({ $0.firstName == "Foo" })



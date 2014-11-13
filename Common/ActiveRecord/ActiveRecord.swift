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

class SwifterActiveRecord /* Probbaly we will use generics and not follow Ruby's approach based on subclassing. Methods like find() and get() need to return a correct types. */ {
    
    init() {
        let properties = listProperties()
        // TODO migrate properties scheme to DB scheme.
    }
    
    private func listProperties() -> [SwifterActiveRecordField]? {
        // Extract public properties so we will know
        var results = [SwifterActiveRecordField]()
        let classInfoDump = reflect(self)
        for var index = 1; index < classInfoDump.count; ++index {
            let field = classInfoDump[index]
            results.append(SwifterActiveRecordField(name: field.0))
            print("\(field.1.valueType)")
        }
        return results
    }
    
    func commit(error: NSErrorPointer) -> Bool {
        //TODO commit changes to DB.
        return false
    }
}

// An example model class.

class Person: SwifterActiveRecord {
    var firstName: String?
    var lastName: String?
    var age: UInt?
}

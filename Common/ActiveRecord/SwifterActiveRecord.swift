//
//  ActiveRecord.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

struct SwifterActiveRecordField {
    let name: String?
    init(name: String?) {
        self.name = name ?? "unknonw"
    }
}

protocol WithInit {
    init()
}

class SwifterActiveRecord<T: WithInit> {
    
    init() {

    }
    
    private func scheme(error: NSErrorPointer?) -> [SwifterActiveRecordField] {
        var results = [SwifterActiveRecordField]()
        let classInfoDump = reflect(T())
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



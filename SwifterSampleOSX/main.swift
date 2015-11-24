//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

class SwiftyJSONSerializer: Serializer {
    func serialize(object: Any) throws -> String {
        guard let obj = object as? JSON,
            let rawString = obj.rawString() else {
                throw SerializationError.InvalidObject
        }
        return rawString
    }
}

let server = demoServer(NSBundle.mainBundle().resourcePath!)

do {
    server["/SwiftyJSON"] = { request in
        let serialize = SwiftyJSONSerializer()
        let js: JSON = ["return": "OK", "isItAJSON": true, "code" : 200]
        return .OK(.Custom(serialize, js))
    }
    server["/testAfterBaseRoute"] = { request in
        return .OK(.Html("ok !"))
    }
    try server.start(9080)
    print("Server has started ( port = 9080 ). Try to connect now...")
    NSRunLoop.mainRunLoop().run()
} catch {
    print("Server start error: \(error)")
}
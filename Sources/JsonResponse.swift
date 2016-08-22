//
//  JsonResponse.swift
//  Swifter
//
//  Created by Dawid Szymczak on 15/08/16.
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import Foundation


public class JsonResponse: Response {
    public override func content() throws -> (contentLength: Int, contentString: String) {
        #if os(Linux)
            let data = [UInt8]("Not ready for Linux.".utf8)
            return (data.count, {
                try $0.write(data)
            })
        #else
            guard NSJSONSerialization.isValidJSONObject(self.contentObject) else {
                throw SerializationError.InvalidObject
            }
            let json = try NSJSONSerialization.dataWithJSONObject(self.contentObject, options: NSJSONWritingOptions.PrettyPrinted)
            let data = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(json.bytes), count: json.length))
            // To be fixed
            return (data.count, String(json))
        #endif
    }
}
//
//  CustomResponse.swift
//  Swifter
//
//  Created by Dawid Szymczak on 15/08/16.
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

public class CustomResponse: Response {
    public var closure: (ObjectIdentifier) -> (String)
    
    public init(contentObject: AnyObject, closure: (Any) throws -> String) {
        self.closure = closure
        super.init(contentObject: contentObject)
    }
    
    public override func content() -> (contentLength: Int, contentString: String) {
        let serialised = try closure(ObjectIdentifier(contentObject))
        let data = [UInt8](serialised.utf8)
        return (data.count, serialised)
    }
}
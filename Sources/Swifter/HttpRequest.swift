//
//  HttpRequest.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public enum HttpMethod : String {
    case GET, POST, PUT, DELETE
}

public struct HttpRequest {
    
    public let url: String
    public let urlParams: [(String, String)]
    public let method: HttpMethod
    public let headers: [String: String]
    public let body: [UInt8]?
    public var address: String?
    public var params: [String: String]
    
    public func parseForm() -> [(String, String)] {
        if let body = body {
            return UInt8ArrayToUTF8String(body).split("&").map { (param: String) -> (String, String) in
                let tokens = param.split("=")
                if tokens.count >= 2 {
                    let key = tokens[0].replace("+", new: " ").removePercentEncoding()
                    let value = tokens[1].replace("+", new: " ").removePercentEncoding()
                    return (key, value)
                }
                return ("","")
            }
        }
        return []
    }
}

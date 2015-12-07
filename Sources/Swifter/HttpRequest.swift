//
//  HttpRequest.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public struct HttpRequest {
    
    public let url: String
    public let urlParams: [(String, String)]
    public let method: String
    public let headers: [String: String]
    public let body: String?
    public var capturedUrlGroups: [String]
    public var address: String?
    
    public func parseForm() -> [(String, String)] {
        if let body = body {
            return body.split("&").map { (param: String) -> (String, String) in
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

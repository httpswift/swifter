//
//  HttpRequest.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

public struct HttpRequest {
    
    public let url: String
    public let urlParams: [(String, String)] // http://stackoverflow.com/questions/1746507/authoritative-position-of-duplicate-http-get-query-keys
    public let method: String
    public let headers: [String: String]
	public let body: String?
    public var capturedUrlGroups: [String]
    public var address: String?
    
    public func parseForm() -> [(String, String)] {
        if let body = body {
            return body.componentsSeparatedByString("&").map { (param:String) -> (String, String) in
                let tokens = param.componentsSeparatedByString("=")
                if tokens.count >= 2 {
                    let key = tokens[0].stringByReplacingOccurrencesOfString("+", withString: " ").stringByRemovingPercentEncoding
                    let value = tokens[1].stringByReplacingOccurrencesOfString("+", withString: " ").stringByRemovingPercentEncoding
                    if let key = key, value = value { return (key, value) }
                }
                return ("","")
            }
        }
        return []
    }
}

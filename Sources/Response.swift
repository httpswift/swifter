//
//  Response.swift
//  Swifter
//
//  Created by Dawid Szymczak on 15/08/16.
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public protocol ResponseProtocol {
    var headersArray : [String: String] { get set }
    var contentObject : AnyObject { get set }
    mutating func content() throws -> (contentLength: Int, contentString: [UInt8])
    func headers() -> [String: String]
    func statusCode() -> Int
}

public class Response: ResponseProtocol {
    public var headersArray: [String : String] = ["Server" : "Swifter \(HttpServer.VERSION)"]
    public var contentObject : AnyObject = ""
//    typealias OK = getStatusCode;()
    
    public init(contentObject: AnyObject) {
        self.contentObject = contentObject
    }
    
    public func content() throws -> (contentLength: Int, contentString: [UInt8]) {
        let contentString = String(contentObject);
        let data = [UInt8](contentString.utf8)
        return (data.count, data)
    }
    
    public func headers() -> [String: String] {
        return headersArray
    }
    
    public func statusCode() -> Int {
        return HttpResponse.NotFound.statusCode()
    }
    
    public func reasonPhrase() -> String {
        return HttpResponse.NotFound.reasonPhrase()
    }
    
    public func getStatusCode() -> Int {
        return HttpResponse.NotFound.statusCode()
    }
}
//
//  Html.swift
//  Swifter
//
//  Copyright © 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

private var htmlStackBuffer = [UInt64: [UInt8]]()

public class HtmlResponse: Response {
    
    public required init(integerLiteral value: Int) {
        super.init(200)
        self.headers.append(("Content-Type", "text/html"))
    }
    
    public init(_ status: Int = Status.ok.rawValue, _ closure: ((Void) -> Void)) {
        
        super.init(status)
        
        self.headers.append(("Content-Type", "text/html"))
        
        htmlStackBuffer.removeAll(keepingCapacity: true)
        
        closure()
        
        if let buffer = htmlStackBuffer[Process.tid] {
            self.body = Array<UInt8>(buffer)
        }
    }
}

public func html(_ status: Int = Status.ok.rawValue, _ closure: ((Void) -> Void)? = nil) -> HtmlResponse {
    return HtmlResponse(status) {
        htmlStackBuffer[Process.tid] = [UInt8]()
        htmlStackBuffer[Process.tid]?.reserveCapacity(1024)
        htmlStackBuffer[Process.tid]?.append(contentsOf: "<!DOCTYPE html>".utf8)
        "html" ~ {
            if let closureFound = closure {
                closureFound()
            }
        }
    }
}

infix operator ~

public func ~ (_ left: String, _ closure: ((Void) -> Void)?) {
    
    htmlStackBuffer[Process.tid]?.append(UInt8.lessThan)
    
    var tagName = [UInt8]()
    var tagEnd = false
    
    for c in left.utf8 {
        switch c {
        case UInt8.openingParenthesis:
            tagEnd = true
            htmlStackBuffer[Process.tid]?.append(.space)
        case UInt8.closingParenthesis:
            htmlStackBuffer[Process.tid]?.append(.doubleQuotes)
        case UInt8.equal:
            htmlStackBuffer[Process.tid]?.append(.equal)
            htmlStackBuffer[Process.tid]?.append(.doubleQuotes)
        case UInt8.comma:
            htmlStackBuffer[Process.tid]?.append(.doubleQuotes)
            htmlStackBuffer[Process.tid]?.append(.space)
        default:
            htmlStackBuffer[Process.tid]?.append(c)
        }
        if !tagEnd {
            tagName.append(c)
        }
    }
    
    htmlStackBuffer[Process.tid]?.append(UInt8.greaterThan)
    
    if let closure = closure {
        closure()
    }
    
    htmlStackBuffer[Process.tid]?.append(UInt8.lessThan)
    htmlStackBuffer[Process.tid]?.append(UInt8.slash)
    htmlStackBuffer[Process.tid]?.append(contentsOf: tagName)
    htmlStackBuffer[Process.tid]?.append(UInt8.greaterThan)
}

public func ~ (_ left: String, _ right: String) {
    
    htmlStackBuffer[Process.tid]?.append(UInt8.lessThan)
    
    var tagName = [UInt8]()
    var tagEnd = false
    
    for c in left.utf8 {
        switch c {
        case UInt8.openingParenthesis:
            tagEnd = true
            htmlStackBuffer[Process.tid]?.append(.space)
        case UInt8.closingParenthesis:
            htmlStackBuffer[Process.tid]?.append(.doubleQuotes)
        case UInt8.equal:
            htmlStackBuffer[Process.tid]?.append(.equal)
            htmlStackBuffer[Process.tid]?.append(.doubleQuotes)
        case UInt8.comma:
            htmlStackBuffer[Process.tid]?.append(.doubleQuotes)
            htmlStackBuffer[Process.tid]?.append(.space)
        default:
            htmlStackBuffer[Process.tid]?.append(c)
        }
        if !tagEnd {
            tagName.append(c)
        }
    }
    
    htmlStackBuffer[Process.tid]?.append(UInt8.greaterThan)
    htmlStackBuffer[Process.tid]?.append(contentsOf: right.utf8)
    htmlStackBuffer[Process.tid]?.append(UInt8.lessThan)
    htmlStackBuffer[Process.tid]?.append(UInt8.slash)
    htmlStackBuffer[Process.tid]?.append(contentsOf: tagName)
    htmlStackBuffer[Process.tid]?.append(UInt8.greaterThan)
}

public func 🦄(port: Int, closure: @escaping (((Response) -> Void) -> Void)) {
    do {
        let server = try Server()
        while true {
            try server.serve { (request, responder) in
                closure(responder)
            }
        }
    } catch {
        print(error)
    }
}

public func 🚀(_ responder: ((Response) -> Void), _ text: String? = nil) {
    if let text = text {
        responder(Response([UInt8](text.utf8)))
    } else {
        responder(Response(404))
    }
}

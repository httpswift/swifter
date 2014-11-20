//
//  HttpParser.swift
//
//  Created by Damian Kolakowski on 05/06/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

class HttpParser {
    
    class func err(reason:String) -> NSError {
        return NSError(domain: "HTTP_PARSER", code: 0, userInfo:[NSLocalizedFailureReasonErrorKey : reason])
    }

    func nextHttpRequest(socket: CInt, error:NSErrorPointer = nil) -> HttpRequest? {
        if let statusLine = nextLine(socket, error: error) {
            let statusTokens = split(statusLine, { $0 == " " })
            println(statusTokens)
            if ( statusTokens.count < 3 ) {
                if error != nil { error.memory = HttpParser.err("Invalid status line: \(statusLine)") }
                return nil
            }
            let method = statusTokens[0]
            let path = statusTokens[1]
            let urlParams = extractUrlParams(path)
            // TODO extract query parameters
            if let headers = nextHeaders(socket, error: error) {
                // TODO detect content-type and handle:
                // 'application/x-www-form-urlencoded' -> Dictionary
                // 'multipart' -> Dictionary
                if let contentSize = headers["content-length"]?.toInt() {
                    let body = nextBody(socket, size: contentSize, error: error)
                    return HttpRequest(url: path, urlParams: urlParams, method: method, headers: headers, body: body, capturedUrlGroups: [])
                }
                return HttpRequest(url: path, urlParams: urlParams, method: method, headers: headers, body: nil, capturedUrlGroups: [])
            }
        }
        return nil
    }
    
    private func extractUrlParams(url: String) -> [(String, String)] {
        var result = [(String, String)]()
        let tokens = url.componentsSeparatedByString("?")
        if tokens.count >= 2 {
            for pair in tokens[1].componentsSeparatedByString("&") {
                let keyAndValue = pair.componentsSeparatedByString("=")
                if keyAndValue.count >= 2 {
                    result.append((keyAndValue[0], keyAndValue[1]))
                }
            }
        }
        return result
    }
    
    private func nextBody(socket: CInt, size: Int , error:NSErrorPointer) -> String? {
        var body = ""
        var counter = 0;
        while ( counter < size ) {
            let c = nextUInt8(socket)
            if ( c < 0 ) {
                if error != nil { error.memory = HttpParser.err("IO error while reading body") }
                return nil
            }
            body.append(UnicodeScalar(c))
            counter++;
        }
        return body
    }
    
    private func nextHeaders(socket: CInt, error:NSErrorPointer) -> Dictionary<String, String>? {
        var headers = Dictionary<String, String>()
        while let headerLine = nextLine(socket, error: error) {
            if ( headerLine.isEmpty ) {
                return headers
            }
            let headerTokens = split(headerLine, { $0 == ":" })
            if ( headerTokens.count >= 2 ) {
                // RFC 2616 - "Hypertext Transfer Protocol -- HTTP/1.1", paragraph 4.2, "Message Headers":
                // "Each header field consists of a name followed by a colon (":") and the field value. Field names are case-insensitive."
                // We can keep lower case version.
                let headerName = headerTokens[0].lowercaseString
                let headerValue = headerTokens[1].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                if ( !headerName.isEmpty && !headerValue.isEmpty ) {
                    headers.updateValue(headerValue, forKey: headerName)
                }
            }
        }
        return nil
    }

    private func nextUInt8(socket: CInt) -> Int {
        var buffer = [UInt8](count: 1, repeatedValue: 0);
        let next = recv(socket, &buffer, UInt(buffer.count), 0)
        if next <= 0 { return next }
        return Int(buffer[0])
    }
    
    private func nextLine(socket: CInt, error:NSErrorPointer) -> String? {
        var characters: String = ""
        var n = 0
        do {
            n = nextUInt8(socket)
            if ( n > 13 /* CR */ ) { characters.append(Character(UnicodeScalar(n))) }
        } while ( n > 0 && n != 10 /* NL */)
        if ( n == -1 && characters.isEmpty ) {
            if error != nil { error.memory = Socket.socketLastError("recv(...) failed.") }
            return nil
        }
        return characters
    }
    
    func supportsKeepAlive(headers: Dictionary<String, String>) -> Bool {
        if let value = headers["connection"] {
            return "keep-alive" == value.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).lowercaseString
        }
        return false
    }
}

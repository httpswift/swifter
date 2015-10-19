//
//  HttpParser.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation


enum HttpParserError : ErrorType {
    case RecvFailed(String?)
    case ReadBodyFailed(String?)
    case InvalidStatusLine(String)
}

class HttpParser {
    
    func nextHttpRequest(socket: CInt) throws -> HttpRequest {
        let statusLine = try nextLine(socket)
        let statusLineTokens = statusLine.componentsSeparatedByString(" ")
        print(statusLineTokens)
        if statusLineTokens.count < 3 {
            throw HttpParserError.InvalidStatusLine(statusLine)
        }
        let method = statusLineTokens[0]
        let path = statusLineTokens[1]
        let urlParams = extractUrlParams(path)
        let headers = try nextHeaders(socket)
        if let contentLength = headers["content-length"], let contentLengthValue = Int(contentLength) {
            let body = try nextBody(socket, size: contentLengthValue)
            return HttpRequest(url: path, urlParams: urlParams, method: method, headers: headers, body: body, capturedUrlGroups: [], address: nil)
        }
        return HttpRequest(url: path, urlParams: urlParams, method: method, headers: headers, body: nil, capturedUrlGroups: [], address: nil)
    }
    
    private func extractUrlParams(url: String) -> [(String, String)] {
        guard let query = url.componentsSeparatedByString("?").last else {
            return []
        }
        return query.componentsSeparatedByString("&").map { (param:String) -> (String, String) in
            let tokens = param.componentsSeparatedByString("=")
            guard tokens.count >= 2 else {
                return ("", "")
            }
            guard let k = tokens[0].stringByRemovingPercentEncoding, v = tokens[1].stringByRemovingPercentEncoding else {
                return ("", "")
            }
            return (k, v)
        }
    }
    
    private func nextBody(socket: CInt, size: Int) throws -> String {
        var body = ""
        var counter = 0;
        while counter < size {
            let c = nextInt8(socket)
            if c < 0 {
                throw HttpParserError.ReadBodyFailed(String.fromCString(UnsafePointer(strerror(errno))))
            }
            body.append(UnicodeScalar(c))
            counter++;
        }
        return body
    }
    
    private func nextHeaders(socket: CInt) throws -> [String: String] {
        var requestHeaders = [String: String]()
        repeat {
            let headerLine = try nextLine(socket)
            if headerLine.isEmpty {
                return requestHeaders
            }
            let headerTokens = headerLine.componentsSeparatedByString(":")
            if headerTokens.count >= 2 {
                // RFC 2616 - "Hypertext Transfer Protocol -- HTTP/1.1", paragraph 4.2, "Message Headers":
                // "Each header field consists of a name followed by a colon (":") and the field value. Field names are case-insensitive."
                // We will keep lower case version.
                let headerName = headerTokens[0].lowercaseString
                let headerValue = headerTokens[1].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                if !headerName.isEmpty && !headerValue.isEmpty {
                    requestHeaders.updateValue(headerValue, forKey: headerName)
                }
            }
        } while true
    }

    private func nextInt8(socket: CInt) -> Int {
        var buffer = [UInt8](count: 1, repeatedValue: 0);
        let next = recv(socket as Int32, &buffer, Int(buffer.count), 0)
        if next <= 0 {
            return next
        }
        return Int(buffer[0])
    }
    
    private func nextLine(socket: CInt) throws -> String {
        var characters: String = ""
        var n = 0
        repeat {
            n = nextInt8(socket)
            if ( n > 13 /* CR */ ) { characters.append(Character(UnicodeScalar(n))) }
        } while n > 0 && n != 10 /* NL */
        if n == -1 {
            throw HttpParserError.RecvFailed(String.fromCString(UnsafePointer(strerror(errno))))
        }
        return characters
    }
    
    func supportsKeepAlive(headers: [String: String]) -> Bool {
        if let value = headers["connection"] {
            return "keep-alive" == value.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).lowercaseString
        }
        return false
    }
}

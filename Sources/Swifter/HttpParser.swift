//
//  HttpParser.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif


enum HttpParserError: ErrorType {
    case ReadBodyFailed(String)
    case InvalidStatusLine(String)
    case UnknownRequestMethod(String)
}

class HttpParser {
    
    func readHttpRequest(socket: Socket) throws -> HttpRequest {
        let statusLine = try socket.readLine()
        let statusLineTokens = statusLine.split(" ")
        print(statusLineTokens)
        if statusLineTokens.count < 3 {
            throw HttpParserError.InvalidStatusLine(statusLine)
        }
        
        // Make sure the request is of a known type
        guard let method = HttpRequest.Method(rawValue: statusLineTokens[0]) else {
            throw HttpParserError.UnknownRequestMethod(statusLine)
        }
        
        let path = statusLineTokens[1]
        let urlParams = extractUrlParams(path)
        let headers = try readHeaders(socket)
        if let contentLength = headers["content-length"], let contentLengthValue = Int(contentLength) {
            let body = try readBody(socket, size: contentLengthValue)
            return HttpRequest(url: path, urlParams: urlParams, method: method, headers: headers, body: body, address: nil, params: [:])
        }
        return HttpRequest(url: path, urlParams: urlParams, method: method, headers: headers, body: nil, address: nil, params: [:])
    }
    
    private func extractUrlParams(url: String) -> [(String, String)] {
        guard let query = url.split("?").last else {
            return []
        }
        return query.split("&").map { (param: String) -> (String, String) in
            let tokens = param.split("=")
            guard let name = tokens.first, value = tokens.last else {
                return ("", "")
            }
            return (name.removePercentEncoding(), value.removePercentEncoding())
        }
    }
    
    private func readBody(socket: Socket, size: Int) throws -> [UInt8] {
        var body = [UInt8]()
        var counter = 0
        while counter < size {
            body.append(try socket.read())
            counter++
        }
        return body
    }
    
    private func readHeaders(socket: Socket) throws -> [String: String] {
        var requestHeaders = [String: String]()
        repeat {
            let headerLine = try socket.readLine()
            if headerLine.isEmpty {
                return requestHeaders
            }
            let headerTokens = headerLine.split(":")
            if let name = headerTokens.first, value = headerTokens.last where headerTokens.count == 2 {
                requestHeaders[name.lowercaseString] = value.trim()
            }
        } while true
    }
    
    func supportsKeepAlive(headers: [String: String]) -> Bool {
        if let value = headers["connection"] {
            return "keep-alive" == value.trim()
        }
        return false
    }
}

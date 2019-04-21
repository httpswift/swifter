//
//  HttpParser.swift
//  Swifter
// 
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

enum HttpParserError: Error {
    case invalidStatusLine(String)
}

public class HttpParser {
    
    public init() { }
    
    public func readHttpRequest(_ socket: Socket) throws -> HttpRequest {
        let statusLine = try socket.readLine()
        let statusLineTokens = statusLine.components(separatedBy: " ")
        if statusLineTokens.count < 3 {
            throw HttpParserError.invalidStatusLine(statusLine)
        }
        let request = HttpRequest()
        request.method = statusLineTokens[0]
        request.path = statusLineTokens[1]
        request.queryParams = extractQueryParams(request.path)
        request.headers = try readHeaders(socket)
        if let contentLength = request.headers["content-length"], let contentLengthValue = Int(contentLength) {
            request.body = try readBody(socket, size: contentLengthValue)
        }
        return request
    }
    
    private func extractQueryParams(_ url: String) -> [(String, String)] {
        #if compiler(>=5.0)
        guard let questionMarkIndex = url.firstIndex(of: "?") else {
            return []
        }
        #else
        guard let questionMarkIndex = url.index(of: "?") else {
            return []
        }
        #endif
        let queryStart = url.index(after: questionMarkIndex)

        guard url.endIndex > queryStart else { return [] }

        #if swift(>=4.0)
        let query = String(url[queryStart..<url.endIndex])
        #else
        guard let query = String(url[queryStart..<url.endIndex]) else { return [] }
        #endif

        return query.components(separatedBy: "&")
            .reduce([(String, String)]()) { (result, stringValue) -> [(String, String)] in
                #if compiler(>=5.0)
                guard let nameEndIndex = stringValue.firstIndex(of: "=") else {
                    return result
                }
                #else
                guard let nameEndIndex = stringValue.index(of: "=") else {
                    return result
                }
                #endif
                guard let name = String(stringValue[stringValue.startIndex..<nameEndIndex]).removingPercentEncoding else {
                    return result
                }
                let valueStartIndex = stringValue.index(nameEndIndex, offsetBy: 1)
                guard valueStartIndex < stringValue.endIndex else {
                    return result + [(name, "")]
                }
                guard let value = String(stringValue[valueStartIndex..<stringValue.endIndex]).removingPercentEncoding else {
                    return result + [(name, "")]
                }
                return result + [(name, value)]
        }
    }

    private func readBody(_ socket: Socket, size: Int) throws -> [UInt8] {
        return try socket.read(length: size)
    }
    
    private func readHeaders(_ socket: Socket) throws -> [String: String] {
        var headers = [String: String]()
        while case let headerLine = try socket.readLine(), !headerLine.isEmpty {
            let headerTokens = headerLine.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true).map(String.init)
            if let name = headerTokens.first, let value = headerTokens.last {
                headers[name.lowercased()] = value.trimmingCharacters(in: .whitespaces)
            }
        }
        return headers
    }
    
    func supportsKeepAlive(_ headers: [String: String]) -> Bool {
        if let value = headers["connection"] {
            return "keep-alive" == value.trimmingCharacters(in: .whitespaces)
        }
        return false
    }
}

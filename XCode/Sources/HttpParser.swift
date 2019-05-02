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
        let urlComponents = URLComponents(string: statusLineTokens[1])
        request.path = urlComponents?.path ?? ""
        request.queryParams = urlComponents?.queryItems?.map { ($0.name, $0.value ?? "") } ?? []
        request.headers = try readHeaders(socket)
        if let contentLength = request.headers["content-length"], let contentLengthValue = Int(contentLength) {
            request.body = try readBody(socket, size: contentLengthValue)
        }
        return request
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

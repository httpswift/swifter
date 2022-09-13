//
//  HttpParser.swift
//  Swifter
// 
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

enum HttpParserError: Error, Equatable {
    case invalidStatusLine(String)
    case negativeContentLength
}

public class HttpParser {
    public func readHttpRequest(_ socket: Socket) throws -> HttpRequest {
        try autoreleasepool {
            let statusLine = try socket.readLine()
            let statusLineTokens = statusLine.components(separatedBy: " ")
            if statusLineTokens.count < 3 {
                throw HttpParserError.invalidStatusLine(statusLine)
            }
            let request = HttpRequest()
            request.method = statusLineTokens[0]
            let encodedPath = statusLineTokens[1].addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? statusLineTokens[1]
            let urlComponents = URLComponents(string: encodedPath)
            request.path = urlComponents?.path ?? ""
            request.queryParams = urlComponents?.queryItems?.map { ($0.name, $0.value ?? "") } ?? []
            request.headers = readHeaders(socket)
            if let contentLength = request.headers["content-length"], let contentLengthValue = Int(contentLength),  contentLengthValue > 0  {
                request.body = try readBody(socket, size: contentLengthValue)
            }
            return request
        }
    }
    
    private func readBody(_ socket: Socket, size: Int) throws -> [UInt8] {
        try autoreleasepool { try socket.read(length: size) }
    }
    
    private func readHeaders(_ socket: Socket) -> [String: String] {
        autoreleasepool {
            var headers = [String: String]()
            while  let headerLine = try? socket.readLine(), !headerLine.isEmpty {
                let headerTokens = headerLine.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true).map(String.init)
                headers[headerTokens[0].lowercased()] = headerTokens[1].trimmingCharacters(in: .whitespaces)
                
            }
            return headers
        }
    }
}

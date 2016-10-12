//
//  HttpRequest.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpRequest {
    
    public var path: String = ""
    public var queryParams: [(String, String)] = []
    public var method: String = ""
    public var headers: [String: String] = [:]
    public var body: [UInt8] = []
    public var address: String? = ""
    public var params: [String: String] = [:]
    
    public func hasTokenForHeader(_ headerName: String, token: String) -> Bool {
        guard let headerValue = headers[headerName] else {
            return false
        }
        return headerValue.split(",").filter({ $0.trim().lowercased() == token }).count > 0
    }
    
    public func parseUrlencodedForm() -> [(String, String)] {
        guard let contentTypeHeader = headers["content-type"] else {
            return []
        }
        let contentTypeHeaderTokens = contentTypeHeader.split(";").map { $0.trim() }
        guard let contentType = contentTypeHeaderTokens.first, contentType == "application/x-www-form-urlencoded" else {
            return []
        }
        return String.fromUInt8(body).split("&").map { param -> (String, String) in
            let tokens = param.split("=")
            if let name = tokens.first, let value = tokens.last, tokens.count == 2 {
                return (name.replace(old: "+", " ").removePercentEncoding(),
                        value.replace(old: "+", " ").removePercentEncoding())
            }
            return ("","")
        }
    }
    
    public struct MultiPart {
        
        public let headers: [String: String]
        public let body: [UInt8]
        
        public var name: String? {
            return valueFor("content-disposition", parameter: "name")?.unquote()
        }
        
        public var fileName: String? {
            return valueFor("content-disposition", parameter: "filename")?.unquote()
        }
        
        private func valueFor(_ headerName: String, parameter: String) -> String? {
            return headers.reduce([String]()) { (combined, header: (key: String, value: String)) -> [String] in
                guard header.key == headerName else {
                    return combined
                }
                let headerValueParams = header.value.split(";").map { $0.trim() }
                return headerValueParams.reduce(combined, { (results, token) -> [String] in
                    let parameterTokens = token.split(1, separator: "=")
                    if parameterTokens.first == parameter, let value = parameterTokens.last {
                        return results + [value]
                    }
                    return results
                })
                }.first
        }
    }
    
    public func parseMultiPartFormData() -> [MultiPart] {
        guard let contentTypeHeader = headers["content-type"] else {
            return []
        }
        let contentTypeHeaderTokens = contentTypeHeader.split(";").map { $0.trim() }
        guard let contentType = contentTypeHeaderTokens.first, contentType == "multipart/form-data" else {
            return []
        }
        var boundary: String? = nil
        contentTypeHeaderTokens.forEach({
            let tokens = $0.split("=")
            if let key = tokens.first, key == "boundary" && tokens.count == 2 {
                boundary = tokens.last
            }
        })
        if let boundary = boundary, boundary.utf8.count > 0 {
            return parseMultiPartFormData(body, boundary: "--\(boundary)")
        }
        return []
    }
    
    private func parseMultiPartFormData(_ data: [UInt8], boundary: String) -> [MultiPart] {
        var generator = data.makeIterator()
        var result = [MultiPart]()
        while let part = nextMultiPart(&generator, boundary: boundary, isFirst: result.isEmpty) {
            result.append(part)
        }
        return result
    }
    
    private func nextMultiPart(_ generator: inout IndexingIterator<[UInt8]>, boundary: String, isFirst: Bool) -> MultiPart? {
        if isFirst {
            guard nextMultiPartLine(&generator) == boundary else {
                return nil
            }
        } else {
            let /* ignore */ _ = nextMultiPartLine(&generator)
        }
        var headers = [String: String]()
        while let line = nextMultiPartLine(&generator), !line.isEmpty {
            let tokens = line.split(":")
            if let name = tokens.first, let value = tokens.last, tokens.count == 2 {
                headers[name.lowercased()] = value.trim()
            }
        }
        guard let body = nextMultiPartBody(&generator, boundary: boundary) else {
            return nil
        }
        return MultiPart(headers: headers, body: body)
    }
    
    private func nextMultiPartLine(_ generator: inout IndexingIterator<[UInt8]>) -> String? {
        var result = String()
        while let value = generator.next() {
            if value > HttpRequest.CR {
                result.append(Character(UnicodeScalar(value)))
            }
            if value == HttpRequest.NL {
                break
            }
        }
        return result
    }
    
    static let CR = UInt8(13)
    static let NL = UInt8(10)
    
    private func nextMultiPartBody(_ generator: inout IndexingIterator<[UInt8]>, boundary: String) -> [UInt8]? {
        var body = [UInt8]()
        let boundaryArray = [UInt8](boundary.utf8)
        var matchOffset = 0;
        while let x = generator.next() {
            matchOffset = ( x == boundaryArray[matchOffset] ? matchOffset + 1 : 0 )
            body.append(x)
            if matchOffset == boundaryArray.count {
                body.removeSubrange(CountableRange<Int>(body.count-matchOffset ..< body.count))
                if body.last == HttpRequest.NL {
                    body.removeLast()
                    if body.last == HttpRequest.CR {
                        body.removeLast()
                    }
                }
                return body
            }
        }
        return nil
    }
}

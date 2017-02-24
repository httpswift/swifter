//
//  Http+Misc.swift
//  Swifter
//
//  Copyright © 2017 Damian Kołakowski. All rights reserved.
//

import Foundation

extension Request {
    
    public func hasToken(_ token: String, forHeader headerName: String) -> Bool {
        guard let (_, value) = headers.filter({ $0.0 == headerName }).first else {
            return false
        }
        return value
            .components(separatedBy: ",")
            .filter({ $0.trimmingCharacters(in: .whitespaces).lowercased() == token })
            .count > 0
    }
}

extension Request {
    
    public func parseUrlencodedForm() -> [(String, String)] {
        guard let (_, contentTypeHeader) = headers.filter({ $0.0 == "content-type"}).last else {
            return []
        }
        let contentTypeHeaderTokens = contentTypeHeader.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let contentType = contentTypeHeaderTokens.first, contentType == "application/x-www-form-urlencoded" else {
            return []
        }
        guard let utf8String = String(bytes: body, encoding: .utf8) else {
            // Consider to throw an exception here (examine the encoding from headers).
            return []
        }
        return utf8String.components(separatedBy: "&").map { param -> (String, String) in
            let tokens = param.components(separatedBy: "=")
            if let name = tokens.first?.removingPercentEncoding, let value = tokens.last?.removingPercentEncoding, tokens.count == 2 {
                return (name.replacingOccurrences(of: "+", with: " "),
                        value.replacingOccurrences(of: "+", with: " "))
            }
            return ("","")
        }
    }
}

extension String {
    
    public func unquote() -> String {
        var scalars = self.unicodeScalars;
        if scalars.first == "\"" && scalars.last == "\"" && scalars.count >= 2 {
            scalars.removeFirst();
            scalars.removeLast();
            return String(scalars)
        }
        return self
    }
}

extension UnicodeScalar {
    
    public func asWhitespace() -> UInt8? {
        if self.value >= 9 && self.value <= 13 {
            return UInt8(self.value)
        }
        if self.value == 32 {
            return UInt8(self.value)
        }
        return nil
    }
    
}

extension Request {
    
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
                let headerValueParams = header.value.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }
                return headerValueParams.reduce(combined, { (results, token) -> [String] in
                    let parameterTokens = token.components(separatedBy: "=")
                    if parameterTokens.first == parameter, let value = parameterTokens.last {
                        return results + [value]
                    }
                    return results
                })
                }.first
        }
    }
    
    public func parseMultiPartFormData() -> [MultiPart] {
        guard let (_, contentTypeHeader) = headers.filter({ $0.0 == "content-type"}).last else {
            return []
        }
        let contentTypeHeaderTokens = contentTypeHeader.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }
        guard let contentType = contentTypeHeaderTokens.first, contentType == "multipart/form-data" else {
            return []
        }
        var boundary: String? = nil
        contentTypeHeaderTokens.forEach({
            let tokens = $0.components(separatedBy: "=")
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
            guard nextUTF8MultiPartLine(&generator) == boundary else {
                return nil
            }
        } else {
            let /* ignore */ _ = nextUTF8MultiPartLine(&generator)
        }
        var headers = [String: String]()
        while let line = nextUTF8MultiPartLine(&generator), !line.isEmpty {
            let tokens = line.components(separatedBy: ":")
            if let name = tokens.first, let value = tokens.last, tokens.count == 2 {
                headers[name.lowercased()] = value.trimmingCharacters(in: .whitespaces)
            }
        }
        guard let body = nextMultiPartBody(&generator, boundary: boundary) else {
            return nil
        }
        return MultiPart(headers: headers, body: body)
    }
    
    private func nextUTF8MultiPartLine(_ generator: inout IndexingIterator<[UInt8]>) -> String? {
        var temp = [UInt8]()
        while let value = generator.next() {
            if value > UInt8.cr {
                temp.append(value)
            }
            if value == UInt8.lf {
                break
            }
        }
        return String(bytes: temp, encoding: String.Encoding.utf8)
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
                if body.last == UInt8.lf {
                    body.removeLast()
                    if body.last == UInt8.cr {
                        body.removeLast()
                    }
                }
                return body
            }
        }
        return nil
    }
}

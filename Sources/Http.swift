//
//  Http.swift
//  Swifter
//
//  Copyright © 2016 kolakowski. All rights reserved.
//

import Foundation

open class Request {
    
    public enum HttpVersion { case http10, http11 }
    
    public var httpVersion = HttpVersion.http10
    
    public var method = ""
    
    public var path = ""
    
    public var query = [(String, String)]()
    
    public var headers = [(String, String)]()
    
    public var body = [UInt8]()
    
    public var contentLength = 0
}

open class Response {
    
    public init() { }
    
    public init(_ status: Status = Status.ok) {
        self.status = status.rawValue
    }
    
    public init(_ status: Int = Status.ok.rawValue) {
        self.status = status
    }
    
    public init(_ body: Array<UInt8>) {
        self.body.append(contentsOf: body)
    }
    
    public init(_ body: ArraySlice<UInt8>) {
        self.body.append(contentsOf: body)
    }
    
    public var status = Status.ok.rawValue
    
    public var headers = [(String, String)]()
    
    public var body = [UInt8]()
    
    public var processingSuccesor: IncomingDataProcessor? = nil
}

public class TextResponse: Response {
    
    public init(_ status: Int = Status.ok.rawValue, _ text: String) {
        super.init(status)
        self.headers.append(("Content-Type", "text/plain"))
        self.body = [UInt8](text.utf8)
    }
}

public enum Status: Int {
    case `continue` = 100
    case switchingProtocols = 101
    case ok = 200
    case created = 201
    case accepted = 202
    case noContent = 204
    case resetContent = 205
    case partialContent = 206
    case movedPerm = 301
    case notModified = 304
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case internalServerError = 500
}

public class HttpIncomingDataPorcessor: Hashable, IncomingDataProcessor {
    
    private enum State {
        case waitingForHeaders
        case waitingForBody
    }
    
    private var state = State.waitingForHeaders
    
    private let socket: Int32
    private var buffer = Array<UInt8>()
    private var request = Request()
    private let callback: ((Request) throws -> Void)
    
    public init(_ socket: Int32, _ closure: @escaping ((Request) throws -> Void)) {
        self.socket = socket
        self.callback = closure
    }
    
    public static func == (lhs: HttpIncomingDataPorcessor, rhs: HttpIncomingDataPorcessor) -> Bool {
        return lhs.socket == rhs.socket
    }
    
    public var hashValue: Int { return Int(self.socket) }
    
    public func process(_ chunk: ArraySlice<UInt8>) throws {
        
        switch self.state {
            
        case .waitingForHeaders:
            
            guard self.buffer.count + chunk.count < 4096 else {
                throw SwifterError.httpError("Headers size exceeds the limit.")
            }
            
            var iterator = chunk.makeIterator()
            
            while let byte = iterator.next() {
                if byte != UInt8.cr {
                    buffer.append(byte)
                }
                if buffer.count >= 2 && buffer[buffer.count-1] == UInt8.lf && buffer[buffer.count-2] == UInt8.lf {
                    self.buffer.removeLast(2)
                    self.request = try self.consumeHeader(buffer)
                    self.buffer.removeAll(keepingCapacity: true)
                    let left = [UInt8](iterator)
                    self.state = .waitingForBody
                    try self.process(left[0..<left.count])
                    break
                }
            }
            
        case .waitingForBody:
            
            guard self.request.body.count + chunk.count <= request.contentLength else {
                throw SwifterError.httpError("Peer sent more data then required ('Content-Length' = \(request.contentLength).")
            }
            
            request.body.append(contentsOf: chunk)
            
            if request.body.count == request.contentLength {
                self.state = .waitingForHeaders
                try self.callback(request)
            }
        }
    }
    
    private func consumeHeader(_ data: [UInt8]) throws -> Request {
        
        let lines = data.split(separator: UInt8.lf)
        
        guard let requestLine = lines.first else {
            throw SwifterError.httpError("No status line.")
        }
        
        let requestLineTokens = requestLine.split(separator: UInt8.space)
        
        guard requestLineTokens.count >= 3 else {
            throw SwifterError.httpError("Invalid status line.")
        }
        
        let request = Request()
        
        if requestLineTokens[2] == [0x48, 0x54,  0x54,  0x50, 0x2f, 0x31, 0x2e, 0x30] {
            request.httpVersion = .http10
        } else if requestLineTokens[2] == [0x48, 0x54,  0x54,  0x50, 0x2f, 0x31, 0x2e, 0x31] {
            request.httpVersion = .http11
        } else {
            throw SwifterError.httpError("Invalid http version: \(requestLineTokens[2])")
        }
        
        request.headers = lines
            .dropFirst()
            .map { line in
                let headerTokens = line.split(separator: UInt8.colon, maxSplits: 1)
                if let name = headerTokens.first, let value = headerTokens.last {
                    if let nameString = String(bytes: name, encoding: String.Encoding.ascii),
                        let valueString = String(bytes: value, encoding: String.Encoding.ascii) {
                        return (nameString.lowercased(), valueString.trimmingCharacters(in: CharacterSet.whitespaces))
                    }
                }
                return ("", "")
        }
        
        if let (_, value) = request.headers
            .filter({ $0.0 == "content-length" })
            .first {
            guard let contentLength = Int(value) else {
                throw SwifterError.httpError("Invalid 'Content-Length' header value \(value).")
            }
            request.contentLength = contentLength
        }
        
        guard let method = String(bytes: requestLineTokens[0], encoding: .ascii) else {
            throw SwifterError.httpError("Invalid 'method' value \(requestLineTokens[0]).")
        }
        
        request.method = method
        
        guard let path = String(bytes: requestLineTokens[1], encoding: .ascii) else {
            throw SwifterError.httpError("Invalid 'path' value \(requestLineTokens[1]).")
        }
        
        let queryComponents = path.components(separatedBy: "?")
        
        if queryComponents.count > 1, let first = queryComponents.first, let last = queryComponents.last {
            request.path = first
            request.query = last
                .components(separatedBy: "&")
                .reduce([(String, String)]()) { (c, s) -> [(String, String)] in
                    let tokens = s.components(separatedBy: "=")
                    if let name = tokens.first, let value = tokens.last {
                        if let nameDecoded = name.removingPercentEncoding, let valueDecoded = value.removingPercentEncoding {
                            return c + [(nameDecoded, tokens.count > 1 ? valueDecoded : "")]
                        }
                    }
                    return c
            }
        } else {
            request.path = path
        }
        
        return request
    }
}

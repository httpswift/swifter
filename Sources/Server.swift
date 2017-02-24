//
//  Misc.swift
//  Swifter
//
//  Copyright © 2017 Damian Kołakowski. All rights reserved.
//

import Foundation

public class Server {
    
    private var processors = [Int32 : IncomingDataProcessor]()
    
    private let io: IO
    
    public init(_ port: in_port_t = 8080, forceIPv4: Bool = false) throws {
        #if os(Linux)
            self.io = try LinuxIO(port, forceIPv4: forceIPv4)
        #else
            self.io = try MacOSIO(port, forceIPv4: forceIPv4)
        #endif
    }
    
    public func serve(_ callback: @escaping ((request: Request, responder: ((Response) -> Void))) -> Void) throws {
        
        try self.io.wait { event in
            
            switch event {
                
            case .connect(_, let socket):
                
                self.processors[socket] = HttpIncomingDataPorcessor(socket) { request in
                    callback((request, { response in
                        let keepIOSession = self.supportsKeepAlive(request.headers) || request.httpVersion == .http11
                        var data = [UInt8]()
                        data.reserveCapacity(1024 + response.body.count)
                        data.append(contentsOf: [UInt8]("HTTP/\(request.httpVersion == .http10 ? "1.0" : "1.1") \(response.status) OK\r\n".utf8))
                        for (name, value) in response.headers {
                            data.append(contentsOf: [UInt8]("\(name): \(value)\r\n".utf8))
                        }
                        if keepIOSession {
                            data.append(contentsOf: [UInt8]("Connection: keep-alive\r\n".utf8))
                        }
                        data.append(contentsOf: [UInt8]("Content-Length: \(response.body.count)\r\n\r\n".utf8))
                        data.append(contentsOf: response.body)
                        do {
                            try self.io.write(socket, data) {
                                if let sucessor = response.processingSuccesor {
                                    self.processors[socket] = sucessor
                                    return .continue
                                }
                                return keepIOSession ? .continue : .terminate
                            }
                        } catch {
                            self.processors.removeValue(forKey: socket)
                        }
                    }))
                }
                
            case .disconnect(_, let socket):
                
                self.processors.removeValue(forKey: socket)
                
            case .data(_, let socket, let chunk):
                
                do {
                    try self.processors[socket]?.process(chunk)
                } catch {
                    self.processors.removeValue(forKey: socket)
                    self.io.finish(socket)
                }
            }
        }
    }
    
    private func supportsKeepAlive(_ headers: Array<(String, String)>) -> Bool {
        if let (_, value) = headers.filter({ $0.0 == "connection" }).first {
            return "keep-alive" == value.trimmingCharacters(in: CharacterSet.whitespaces)
        }
        return false
    }
    
    private func closeConnection(_ headers: Array<(String, String)>) -> Bool {
        if let (_, value) = headers.filter({ $0.0 == "connection" }).first {
            return "close" == value.trimmingCharacters(in: CharacterSet.whitespaces)
        }
        return false
    }
}

public protocol IncomingDataProcessor {
    
    func process(_ chunk: ArraySlice<UInt8>) throws
}

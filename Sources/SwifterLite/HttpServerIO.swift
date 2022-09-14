//
//  HttpServerIO.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//
//  SwifterLite
//  Copyright (c) 2022 Todd Bruss. All rights reserved.
//

import Foundation
import Dispatch

public protocol HttpServerIODelegate: AnyObject {
    func socketConnectionReceived(_ socket: Socket)
}

open class HttpServerIO {
    internal init(delegate: HttpServerIODelegate? = nil, socket: Socket = Socket(socketFileDescriptor: -1), sockets: Set<Socket> = Set<Socket>(), stateValue: Int32 = HttpServerIOState.stopped.rawValue) {
        self.delegate = delegate
        self.socket = socket
        self.sockets = sockets
        self.stateValue = stateValue
    }
        
    public weak var delegate: HttpServerIODelegate?
    private var socket = Socket(socketFileDescriptor: -1)
    private var sockets = Set<Socket>()
    
    public enum HttpServerIOState: Int32 {
        case starting
        case running
        case stopping
        case stopped
    }
    
    private var stateValue: Int32 = HttpServerIOState.stopped.rawValue
    
    public private(set) var state: HttpServerIOState {
        
        get {
            HttpServerIOState(rawValue: stateValue) ?? HttpServerIOState.stopped
        }
        
        set(state) {
            self.stateValue = state.rawValue
        }
    }
        
    private let queue = DispatchQueue.main

    public func port() throws -> Int {
       Int(try socket.port())
    }
    
    deinit {
        stop()
    }
    
    public func start(_ port: in_port_t, priority: DispatchQoS.QoSClass = .userInteractive) throws {
        try autoreleasepool {
            self.socket = try Socket.tcpSocketForListen(port, SOMAXCONN, nil)
            self.state = .running
            DispatchQueue.global(qos: priority).async { [self] in
                while let socket = try? socket.acceptClientSocket() {
                    DispatchQueue.global(qos: priority).async { [self] in
                        
                        queue.async {
                            self.sockets.insert(socket)
                        }
                        
                        handleConnection(socket)
                        
                        queue.async {
                            self.sockets.remove(socket)
                        }
                    }
                }
                stop()
            }
        }
    }
    
    public func stop() {
        try autoreleasepool {
            self.state = .stopping

            for socket in self.sockets {
                socket.close()
            }
            
            self.sockets.removeAll(keepingCapacity: false)
            socket.close()
            self.state = .stopped
        }
    }
    
    open func dispatch(_ request: HttpRequest) -> dispatchHttpReq {
        ([:], { _ in HttpResponse.notFound(nil) })
    }
    
    private func handleConnection(_ socket: Socket) {
        let parser = HttpParser()
        while let request = try? parser.readHttpRequest(socket) {
            request.address = "127.0.0.1"
            
            let (params, handler) = self.dispatch(request)
            request.params = params
            
            let response = handler(request)
            var keepConnection = parser.supportsKeepAlive(request.headers)
            
            do {
                keepConnection = try self.respond(socket, response: response, keepAlive: keepConnection)
            } catch {
                socket.close()
                break
            }
                    
            if !keepConnection { break }
        }
        socket.close()
    }
    
    private struct InnerWriteContext: HttpResponseBodyWriter {
        let socket: Socket
    
        func write(byts data: [UInt8]) throws {
            try socket.writeUInt8(data)
        }
        
        func write(data: Data) throws {
            try socket.writeData(data)
        }
    }
    
    private func respond(_ socket: Socket, response: HttpResponse, keepAlive: Bool) throws -> Bool {
        try autoreleasepool {
            var responseHeader = "HTTP/1.1 \(response.statusCode) \(response.reasonPhrase)\r\n"
            
            let content = response.content()
            responseHeader.append("Content-Length: \(content.length)\r\n")
            
            if keepAlive {
                responseHeader.append("Connection: keep-alive\r\n")
            }
            
            for (name, value) in response.headers() {
                responseHeader.append("\(name): \(value)\r\n")
            }
            responseHeader.append("\r\n")
            
            try socket.writeUtf8(responseHeader)
            
            guard
                let writeClosure = content.write
            else {
                return keepAlive
            }
            
            try writeClosure(InnerWriteContext(socket: socket))
            
            return keepAlive
        }
    }
}

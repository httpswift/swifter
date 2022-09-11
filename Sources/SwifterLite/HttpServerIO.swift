//
//  HttpServerIO.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation
import Dispatch

public protocol HttpServerIODelegate: AnyObject {
    func socketConnectionReceived(_ socket: Socket)
}

open class HttpServerIO {
    internal init(delegate: HttpServerIODelegate? = nil, socket: Socket = Socket(socketFileDescriptor: -1), sockets: Set<Socket> = Set<Socket>(), stateValue: Int32 = HttpServerIOState.stopped.rawValue, listenAddressIPv4: String? = nil, listenAddressIPv6: String? = nil) {
        self.delegate = delegate
        self.socket = socket
        self.sockets = sockets
        self.stateValue = stateValue
        self.listenAddressIPv4 = listenAddressIPv4
        self.listenAddressIPv6 = listenAddressIPv6
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
    
    public var operating: Bool { return self.state == .running }
    public var listenAddressIPv4: String?
    public var listenAddressIPv6: String?
    
    //private let queue = DispatchQueue(label: "swifter.lite.socket")
    private let queue = DispatchQueue.main

    public func port() throws -> Int {
       Int(try socket.port())
    }
    
    public func isIPv4() throws -> Bool {
        try socket.isIPv4()
    }
    
    deinit {
        stop()
    }
    
    public func start(_ port: in_port_t, forceIPv4: Bool = true, priority: DispatchQoS.QoSClass = DispatchQoS.QoSClass.userInteractive) throws {
        guard !self.operating else { return }
        stop()
        self.state = .starting
        let address = forceIPv4 ? listenAddressIPv4 : listenAddressIPv6
        self.socket = try Socket.tcpSocketForListen(port, forceIPv4, SOMAXCONN, address)
        self.state = .running
        DispatchQueue.global(qos: priority).async { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.operating else { return }
            while let socket = try? strongSelf.socket.acceptClientSocket() {
                DispatchQueue.global(qos: priority).async { [weak self] in
                    guard let strongSelf = self else { return }
                    guard strongSelf.operating else { return }
                    strongSelf.queue.async {
                        strongSelf.sockets.insert(socket)
                    }
                    
                    strongSelf.handleConnection(socket)
                    
                    strongSelf.queue.async {
                        strongSelf.sockets.remove(socket)
                    }
                }
            }
            strongSelf.stop()
        }
    }
    
    public func stop() {
        guard self.operating else { return }
        self.state = .stopping
        // Shutdown connected peers because they can live in 'keep-alive' or 'websocket' loops.
        for socket in self.sockets {
            socket.close()
        }
        self.queue.sync {
            self.sockets.removeAll(keepingCapacity: false)
        }
        socket.close()
        self.state = .stopped
    }
    
    open func dispatch(_ request: HttpRequest) -> dispatchHttpReq {
        ([:], { _ in HttpResponse.notFound(nil) })
    }
    
    private func handleConnection(_ socket: Socket) {
        let parser = HttpParser()
        while self.operating, let request = try? parser.readHttpRequest(socket) {
            let request = request
            request.address = try? socket.peername()
            let (params, handler) = self.dispatch(request)
            request.params = params
            let response = handler(request)
            var keepConnection = parser.supportsKeepAlive(request.headers)
            do {
                if self.operating {
                    keepConnection = try self.respond(socket, response: response, keepAlive: keepConnection)
                }
            } catch {
                //print("Failed to send response: \(error)")
            }
            
//            if let session = response.socketSession() {
//                delegate?.socketConnectionReceived(socket)
//                session(socket)
//                break
//            }
            
            if !keepConnection { break }
        }
        socket.close()
    }
    
    private struct InnerWriteContext: HttpResponseBodyWriter {
        let socket: Socket
    
        func write(bytes data: [UInt8]) throws {
            try socket.writeUInt8(data)
        }
        
        func write(data: Data) throws {
            try socket.writeData(data)
        }
    }
    
    private func respond(_ socket: Socket, response: HttpResponse, keepAlive: Bool) throws -> Bool {
        guard self.operating else { return false }
        
        var responseHeader = String()
        
        responseHeader.append("HTTP/1.1 \(response.statusCode) \(response.reasonPhrase)\r\n")
        
        let content = response.content()
        
        if content.length >= 0 {
            responseHeader.append("Content-Length: \(content.length)\r\n")
        }
        
        if keepAlive && content.length != -1 {
            responseHeader.append("Connection: keep-alive\r\n")
        }
        
        for (name, value) in response.headers() {
            responseHeader.append("\(name): \(value)\r\n")
        }
        
        responseHeader.append("\r\n")
        
        try socket.writeUTF8(responseHeader)
        
        if let writeClosure = content.write {
            let context = InnerWriteContext(socket: socket)
            try writeClosure(context)
        }
        
        return keepAlive && content.length != -1
    }
}

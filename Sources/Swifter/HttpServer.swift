//
//  HttpServer.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpServer {
    
    static let VERSION = "1.0.2";
    
    public typealias Handler = HttpRequest -> HttpResponse
    
    private var router = HttpRouter()
    
    private var listenSocket: Socket = Socket(socketFileDescriptor: -1)
    private var clientSockets: Set<Socket> = []
    private let clientSocketsLock = 0
    
    public init() { }
    
    public subscript(path: String) -> Handler? {
        set {
            if let newValue = newValue {
                router.register(path, handler: newValue)
            }
            else {
                router.unregister(path)
            }
        }
        get {
            return nil
        }
    }
    
    public var routes: [String] {
        return router.routes()
    }
    
    public func start(listenPort: in_port_t = 8080) throws {
        stop()
        listenSocket = try Socket.tcpSocketForListen(listenPort)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            while let socket = try? self.listenSocket.acceptClientSocket() {
                HttpServer.lock(self.clientSocketsLock) {
                    self.clientSockets.insert(socket)
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                    let socketAddress = try? socket.peername()
                    let httpParser = HttpParser()
                    while let request = try? httpParser.readHttpRequest(socket) {
                        let keepAlive = httpParser.supportsKeepAlive(request.headers)
                        let response: HttpResponse
                        if let (params, handler) = self.router.select(request.url) {
                            let updatedRequest = HttpRequest(url: request.url, urlParams: request.urlParams, method: request.method, headers: request.headers, body: request.body, address: socketAddress, params: params)
                            response = handler(updatedRequest)
                        } else {
                            response = HttpResponse.NotFound
                        }
                        do {
                            try HttpServer.respond(socket, response: response, keepAlive: keepAlive)
                        } catch {
                            print("Failed to send response: \(error)")
                            break
                        }
                        if !keepAlive { break }
                    }
                    socket.release()
                    HttpServer.lock(self.clientSocketsLock) {
                        self.clientSockets.remove(socket)
                    }
                }
            }
            self.stop()
        }
    }

    public func stop() {
        listenSocket.release()
        HttpServer.lock(self.clientSocketsLock) {
            for socket in self.clientSockets {
                socket.shutdwn()
            }
            self.clientSockets.removeAll(keepCapacity: true)
        }
    }
    
    private class func lock(handle: AnyObject, closure: () -> ()) {
        objc_sync_enter(handle)
        closure()
        objc_sync_exit(handle)
    }
    
    private class func respond(socket: Socket, response: HttpResponse, keepAlive: Bool) throws {
        try socket.writeUTF8("HTTP/1.1 \(response.statusCode()) \(response.reasonPhrase())\r\n")
        
        let length = response.body()?.count ?? 0
        try socket.writeUTF8("Content-Length: \(length)\r\n")
        
        if keepAlive {
            try socket.writeUTF8("Connection: keep-alive\r\n")
        }
        for (name, value) in response.headers() {
            try socket.writeUTF8("\(name): \(value)\r\n")
        }
        try socket.writeUTF8("\r\n")
        if let body = response.body() {
            try socket.writeUInt8(body)
        }
    }
}


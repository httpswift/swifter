//
//  HttpServer.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

#if os(Linux)
    import Glibc
    import NSLinux
#endif

public class HttpServerIO {
    
    private var listenSocket: Socket = Socket(socketFileDescriptor: -1)
    private var clientSockets: Set<Socket> = []
    private let clientSocketsLock = NSLock()
    
    public func start(listenPort: in_port_t = 8080) throws {
        stop()
        listenSocket = try Socket.tcpSocketForListen(listenPort)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            while let socket = try? self.listenSocket.acceptClientSocket() {
                self.lock(self.clientSocketsLock) {
                    self.clientSockets.insert(socket)
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                    self.handleConnection(socket)
                    self.lock(self.clientSocketsLock) {
                        self.clientSockets.remove(socket)
                    }
                })
            }
            self.stop()
        }
    }
    
    public func handleConnection(socket: Socket) {
        let address = try? socket.peername()
        let parser = HttpParser()
        while let request = try? parser.readHttpRequest(socket) {
            var request = request
            let keepAlive = parser.supportsKeepAlive(request.headers)
            let (params, handler) = self.dispatch(request.method, url: request.url)
            request.address = address
            request.params = params;
            let response = handler(request)
            do {
                try self.respond(socket, response: response, keepAlive: keepAlive)
            } catch {
                print("Failed to send response: \(error)")
                break
            }
            if !keepAlive { break }
        }
        socket.release()
    }
    
    public func dispatch(method: String, url: String) -> ([String: String], HttpRequest -> HttpResponse) {
        return ([:], { _ in HttpResponse.NotFound })
    }
    
    public func stop() {
        listenSocket.release()
        lock(self.clientSocketsLock) {
            for socket in self.clientSockets {
                socket.shutdwn()
            }
            self.clientSockets.removeAll(keepCapacity: true)
        }
    }
    
    private func lock(handle: NSLock, closure: () -> ()) {
        handle.lock()
        closure()
        handle.unlock();
    }
    
    private func respond(socket: Socket, response: HttpResponse, keepAlive: Bool) throws {
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

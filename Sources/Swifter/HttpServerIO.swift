//
//  HttpServer.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//


#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

public class HttpServerIO {
    
    private var socket = Socket(socketFileDescriptor: -1)
    private var sockets = Set<Socket>()
    
    public private(set) var running = false
    
    public func port() throws -> Int {
        return Int(try socket.port())
    }
    
    public func isIPv4() throws -> Bool {
        return try socket.isIPv4()
    }
    
    deinit {
        stop()
    }
    
    @available(OSX 10.10, *)
    public func start(_ listenPort: in_port_t = 8080, forceIPv4: Bool = false) throws {
        stop()
        socket = try Socket.tcpSocketForListen(listenPort, forceIPv4)
        self.running = true
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            while let socket = try? self.socket.acceptClientSocket() {
                DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
                    self.sockets.insert(socket)
                    self.handleConnection(socket)
                    self.sockets.remove(socket)
                }
            }
            self.stop()
            self.running = false
        }
    }
    
    public func stop() {
        // Shutdown connected peers because they can live in 'keep-alive' or 'websocket' loops.
        for socket in self.sockets {
            socket.shutdwn()
        }
        self.sockets.removeAll(keepingCapacity: true)
        socket.release()
        self.running = false
    }
    
    public func dispatch(_ request: HttpRequest) -> ([String: String], (HttpRequest) -> HttpResponse) {
        return ([:], { _ in HttpResponse.notFound })
    }
    
    private func handleConnection(_ socket: Socket) {
        let parser = HttpParser()
        while let request = try? parser.readHttpRequest(socket) {
            let request = request
            request.address = try? socket.peername()
            let (params, handler) = self.dispatch(request)
            request.params = params
            let response = handler(request)
            var keepConnection = parser.supportsKeepAlive(request.headers)
            do {
                keepConnection = try self.respond(socket, response: response, keepAlive: keepConnection)
            } catch {
                print("Failed to send response: \(error)")
                break
            }
            if let session = response.socketSession() {
                session(socket)
                break
            }
            if !keepConnection { break }
        }
        socket.release()
    }
    
    private struct InnerWriteContext: HttpResponseBodyWriter {
        let socket: Socket
        
        func write(_ file: File) throws {
            var offset: off_t = 0
            let _ = sendfile(fileno(file.pointer), socket.socketFileDescriptor, 0, &offset, nil, 0)
        }
        
        func write(_ data: [UInt8]) throws {
            try write(ArraySlice(data))
        }
        
        func write(_ data: ArraySlice<UInt8>) throws {
            try socket.writeUInt8(data)
        }
    }
    
    private func respond(_ socket: Socket, response: HttpResponse, keepAlive: Bool) throws -> Bool {
        try socket.writeUTF8("HTTP/1.1 \(response.statusCode()) \(response.reasonPhrase())\r\n")
        
        let content = response.content()
        
        if content.length >= 0 {
            try socket.writeUTF8("Content-Length: \(content.length)\r\n")
        }
        
        if keepAlive && content.length != -1 {
            try socket.writeUTF8("Connection: keep-alive\r\n")
        }
        
        for (name, value) in response.headers() {
            try socket.writeUTF8("\(name): \(value)\r\n")
        }
        
        try socket.writeUTF8("\r\n")
    
        if let writeClosure = content.write {
            let context = InnerWriteContext(socket: socket)
            try writeClosure(context)
        }
        
        return keepAlive && content.length != -1;
    }
}

#if os(Linux)

public class DispatchQueue {
    
    private static let instance = DispatchQueue()
    
    public struct GlobalAttributes {
        public static let qosBackground: DispatchQueue.GlobalAttributes = GlobalAttributes()
    }
    
    public class func global(attributes: DispatchQueue.GlobalAttributes) -> DispatchQueue {
        return instance
    }
    
    private class DispatchContext {
        let block: ((Void) -> Void)
        init(_ block: ((Void) -> Void)) {
            self.block = block
        }
    }
    
    public func async(execute work: @convention(block) () -> Swift.Void) {
        let context = UnsafeMutablePointer<Void>(OpaquePointer(bitPattern: Unmanaged.passRetained(DispatchContext(work))))
        var pthread: pthread_t = 0
        pthread_create(&pthread, nil, { (context: UnsafeMutablePointer<Swift.Void>?) -> UnsafeMutablePointer<Swift.Void>? in
	    if let context = context {
                let unmanaged = Unmanaged<DispatchContext>.fromOpaque(OpaquePointer(context))
                unmanaged.takeUnretainedValue().block()
                unmanaged.release()
            }
            return nil
        }, context)
    }
}

#endif

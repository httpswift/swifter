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
    
    public enum ServerStatus {
        case Stopped
        case Running
    }
    
    private var listenSocket: Socket = Socket(socketFileDescriptor: -1)
    private var listenPort: in_port_t = 8080
    private var ipv4 = false
    private var listenPriority: Int = DISPATCH_QUEUE_PRIORITY_BACKGROUND
    private var serverStatus: ServerStatus = .Stopped
    
    private var clientSockets: Set<Socket> = []
    private let clientSocketsLock = NSLock()
    
    // Returns the port used by the server for listening connection.
    public var port: Int {
        get {
            return Int(listenPort)
        }
    }
    
    // True if the IPv4 has been forced on start.
    public var forcedIPv4: Bool {
        get {
            return ipv4
        }
    }
    
    // Returns the priority used for dispatch
    public var priority: Int {
        get {
            return listenPriority
        }
    }
    
    // Returns the server status (Running or not).
    public var status: ServerStatus {
        get {
            return serverStatus
        }
    }
    
    public func start(port: in_port_t = 8080, forceIPv4: Bool = false, priority: Int = DISPATCH_QUEUE_PRIORITY_BACKGROUND) throws {
        stop()
        self.listenSocket = try Socket.tcpSocketForListen(port, forceIPv4: forceIPv4)
        self.listenPort = try self.listenSocket.port()
        self.ipv4 = forceIPv4
        self.listenPriority = priority
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            self.serverStatus = .Running
            while let socket = try? self.listenSocket.acceptClientSocket() {
                self.lock(self.clientSocketsLock) {
                    self.clientSockets.insert(socket)
                }
                dispatch_async(dispatch_get_global_queue(priority, 0), {
                    self.handleConnection(socket)
                    self.lock(self.clientSocketsLock) {
                        self.clientSockets.remove(socket)
                    }
                })
            }
            self.stop()
            self.serverStatus = .Stopped
        }
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
    
    public func dispatch(request: HttpRequest) -> ([String: String], HttpRequest -> HttpResponse) {
        return ([:], { _ in HttpResponse.NotFound })
    }
    
    private func handleConnection(socket: Socket) {
        let address = try? socket.peername()
        let parser = HttpParser()
        while let request = try? parser.readHttpRequest(socket) {
            let request = request
            request.address = address
            let (params, handler) = self.dispatch(request)
            request.params = params;
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
    
    private func lock(handle: NSLock, closure: () -> ()) {
        handle.lock()
        closure()
        handle.unlock();
    }
    
    private struct InnerWriteContext: HttpResponseBodyWriter {
        let socket: Socket

        func write(file: File) throws {
            try socket.writeFile(file)
        }

        func write(data: [UInt8]) throws {
            try write(ArraySlice(data))
        }

        func write(data: ArraySlice<UInt8>) throws {
            try socket.writeUInt8(data)
        }
    }
    
    private func respond(socket: Socket, response: HttpResponse, keepAlive: Bool) throws -> Bool {
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

public class NSLock {
    
    private var mutex = pthread_mutex_t()
    
    init() { pthread_mutex_init(&mutex, nil) }
    
    public func lock() { pthread_mutex_lock(&mutex) }
    
    public func unlock() { pthread_mutex_unlock(&mutex) }
    
    deinit { pthread_mutex_destroy(&mutex) }
}


let DISPATCH_QUEUE_PRIORITY_BACKGROUND = 0

private class dispatch_context {
    let block: ((Void) -> Void)
    init(_ block: ((Void) -> Void)) {
        self.block = block
    }
}

func dispatch_get_global_queue(queueId: Int, _ arg: Int) -> Int { return 0 }

func dispatch_async(queueId: Int, _ block: ((Void) -> Void)) {
    let unmanagedDispatchContext = Unmanaged.passRetained(dispatch_context(block))
    let context = UnsafeMutablePointer<Void>(unmanagedDispatchContext.toOpaque())
    var pthread: pthread_t = 0
    pthread_create(&pthread, nil, { (context: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void> in
        let unmanaged = Unmanaged<dispatch_context>.fromOpaque(COpaquePointer(context))
        unmanaged.takeUnretainedValue().block()
        unmanaged.release()
        return context
    }, context)
}
    
#endif


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
    
    private var listenSocket: Socket = Socket(socketFileDescriptor: -1)
    private var clientSockets: Set<Socket> = []
    private let clientSocketsLock = NSLock()
    
    public func start(listenPort: in_port_t = 8080, forceIPv4: Bool = false, priority: Int = DISPATCH_QUEUE_PRIORITY_BACKGROUND) throws {
        stop()
        listenSocket = try Socket.tcpSocketForListen(listenPort, forceIPv4: forceIPv4)
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
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
            let (params, handler) = self.dispatch(request)
            request.address = address
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
        
        func write(file: File) {
            var offset: off_t = 0
            let _ = sendfile(fileno(file.pointer), socket.socketFileDescriptor, 0, &offset, nil, 0)
        }

        func write(data: [UInt8]) {
            write(ArraySlice(data))
        }
        
        func write(data: ArraySlice<UInt8>) {
            do {
                try socket.writeUInt8(data)
            } catch {
                print("\(error)")
            }
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
    
    import Glibc
    
    struct sf_hdtr { }
    
    func sendfile(source: Int32, _ target: Int32, _: off_t, _: UnsafeMutablePointer<off_t>, _: UnsafeMutablePointer<sf_hdtr>, _: Int32) -> Int32 {
        var buffer = [UInt8](count: 1024, repeatedValue: 0)
        while true {
            let readResult = read(source, &buffer, buffer.count)
            guard readResult > 0 else {
                return Int32(readResult)
            }
            var writeCounter = 0
            while writeCounter < readResult {
                let writeResult = write(target, &buffer + writeCounter, readResult - writeCounter)
                guard writeResult > 0 else {
                    return Int32(writeResult)
                }
                writeCounter = writeCounter + writeResult
            }
        }
    }

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

//
//  MacOS.swift
//  Swifter
//
//  Copyright © 2016 kolakowski. All rights reserved.
//

#if os(OSX) || os(iOS)
    
import Foundation

public class MacOSIO: IO {
    
    private var backlog = Dictionary<Int32, Array<(chunk: [UInt8], done: ((Void) -> IODoneAction))>>()
    
    private var peers = Set<Int32>()
    
    private let kernelQueue: KernelQueue
    
    private let server: UInt
    
    public required init(_ port: in_port_t, forceIPv4: Bool, bindAddress: String? = nil) throws {
        
        self.kernelQueue = try KernelQueue()
        
        self.server = UInt(
            try MacOSIO.nonBlockingSocketForListenening(port, forceIPv4: forceIPv4, address: bindAddress)
        )
        
        self.kernelQueue.subscribe(server, .read)
    }
    
    public func write(_ socket: Int32, _ data: Array<UInt8>, _ done: @escaping ((Void) -> IODoneAction)) throws {
        
        let result = Darwin.write(socket, data, data.count)
        
        if result == -1 {
            defer { self.finish(socket) }
            throw SwifterError.writeFailed(Process.error)
        }
        
        if result == data.count {
            if done() == .terminate {
                self.finish(socket)
            }
            return
        }
        
        self.backlog[socket]?.append(([UInt8](data[result..<data.count]), done))
        self.kernelQueue.resume(UInt(socket), .write)
    }
    
    public func wait(_ callback: ((IOEvent) -> Void)) throws {
        try self.kernelQueue.wait { signal in
            switch signal.event {
            case .read:
                if signal.ident == self.server {
                    let client = try MacOSIO.acceptAndConfigureClientSocket(Int32(signal.ident))
                    self.peers.insert(client)
                    self.backlog[Int32(client)] = []
                    kernelQueue.subscribe(UInt(client), .read)
                    kernelQueue.subscribe(UInt(client), .write)
                    kernelQueue.pause(UInt(client), .write)
                    callback(.connect("", Int32(client)))
                } else {
                    var chunk = [UInt8](repeating: 0, count: signal.data)
                    let result = Darwin.read(Int32(signal.ident), &chunk, signal.data)
                    if result <= 0 {
                        finish(Int32(signal.ident))
                        callback(.disconnect("", Int32(signal.ident)))
                    } else {
                        callback(.data("", Int32(signal.ident), chunk[0..<result]))
                    }
                }
            case .write:
                while let backlogElement = self.backlog[Int32(signal.ident)]?.first {
                    var chunk = backlogElement.chunk
                    let result = Darwin.write(Int32(signal.ident), &chunk, min(chunk.count, signal.data))
                    if result == -1 {
                        finish(Int32(signal.ident))
                        callback(.disconnect("", Int32(signal.ident)))
                        return
                    }
                    if result < chunk.count {
                        let leftData = [UInt8](chunk[result..<chunk.count])
                        self.backlog[Int32(signal.ident)]?.remove(at: 0)
                        self.backlog[Int32(signal.ident)]?.insert((chunk: leftData, done: backlogElement.done), at: 0)
                        return
                    }
                    self.backlog[Int32(signal.ident)]?.removeFirst()
                    if backlogElement.done() == .terminate {
                        self.finish(Int32(signal.ident))
                        callback(.disconnect("", Int32(signal.ident)))
                        return
                    }
                }
                self.kernelQueue.pause(signal.ident, .write)
            case .error:
                if signal.ident == self.server {
                    throw SwifterError.async(Process.error)
                } else {
                    self.finish(Int32(signal.ident))
                    callback(.disconnect("", Int32(signal.ident)))
                }
            }
        }
    }
    
    deinit {
        closeAllOpenedSockets()
    }
    
    public func finish(_ socket: Int32) {
        self.backlog[socket] = []
        self.peers.remove(socket)
        let _ = Darwin.close(socket)
    }
    
    public func closeAllOpenedSockets() {
        for client in self.peers {
            let _ = Darwin.close(client)
        }
        self.peers.removeAll(keepingCapacity: true)
        let _ = Darwin.close(Int32(server))
    }
    
    public static func nonBlockingSocketForListenening(_ port: in_port_t = 8080, forceIPv4: Bool = false, address: String? = nil) throws -> Int32 {
        
        let server = Darwin.socket(forceIPv4 ? AF_INET : AF_INET6, SOCK_STREAM, 0)
        
        guard server != -1 else {
            throw SwifterError.socketCreation(Process.error)
        }
        
        var value: Int32 = 1
        if Darwin.setsockopt(server, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(MemoryLayout<Int32>.size)) == -1 {
            defer { let _ = Darwin.close(server) }
            throw SwifterError.setReuseAddrFailed(Process.error)
        }
        
        do {
            try setSocketNonBlocking(server)
            try setSocketNoSigPipe(server)
            if forceIPv4 {
                try bind(toSocket: server, port: port, andIPv4Address: address)
            } else {
                try bind(toSocket: server, port: port, andAddress: address)
            }
        } catch {
            let _ = Darwin.close(server)
            throw error
        }
        
        if Darwin.listen(server, SOMAXCONN) == -1 {
            defer { let _ = Darwin.close(server) }
            throw SwifterError.listenFailed(Process.error)
        }
        
        return server
    }
    
    public static func acceptAndConfigureClientSocket(_ socket: Int32) throws -> Int32 {
        
        guard case let client = Darwin.accept(socket, nil, nil), client != -1 else {
            throw SwifterError.acceptFailed(Process.error)
        }
        
        try self.setSocketNonBlocking(client)
        try self.setSocketNoSigPipe(client)
        
        return client
    }
    
    public static func bind(toSocket socket: Int32, port: in_port_t, andIPv4Address address: String? = nil) throws  {
        
        var addr = sockaddr_in()
        
        addr.sin_len = __uint8_t(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = port.bigEndian
        
        if let addressFound = address {
            guard addressFound.withCString({ inet_pton(AF_INET, $0, &addr.sin_addr) }) == 1 else {
                throw SwifterError.inetPtonFailed(Errno.description())
            }
        } else {
            addr.sin_addr = in_addr(s_addr: in_addr_t(0))
        }
        
        addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)

        let bindResult = withUnsafePointer(to: &addr) {
            Darwin.bind(socket, UnsafePointer<sockaddr>(OpaquePointer($0)), socklen_t(MemoryLayout<sockaddr_in>.size))
        }
        
        guard bindResult != -1 else {
             throw SwifterError.bindFailed(Errno.description())
        }
    }
    
    public static func bind(toSocket socket: Int32, port: in_port_t, andAddress address: String? = nil) throws {
        
        var addr = sockaddr_in6()
        
        addr.sin6_len = __uint8_t(MemoryLayout<sockaddr_in6>.size)
        addr.sin6_family = sa_family_t(AF_INET6)
        addr.sin6_port = port.bigEndian
        
        if let addressFound = address {
            guard addressFound.withCString({ inet_pton(AF_INET6, $0, &addr.sin6_addr) }) == 1 else {
                throw SwifterError.inetPtonFailed(Errno.description())
            }
        } else {
            addr.sin6_addr = in6addr_any
        }
        
        addr.sin6_scope_id = 0
        
        let bindResult = withUnsafePointer(to: &addr) {
            Darwin.bind(socket, UnsafePointer<sockaddr>(OpaquePointer($0)), socklen_t(MemoryLayout<sockaddr_in6>.size))
        }
        
        guard bindResult != -1 else {
            throw SwifterError.bindFailed(Errno.description())
        }
    }
    
    public static func setSocketNonBlocking(_ socket: Int32) throws {
        if Darwin.fcntl(socket, F_SETFL, Darwin.fcntl(socket, F_GETFL, 0) | O_NONBLOCK) == -1 {
            throw SwifterError.setNonBlockFailed(Process.error)
        }
    }
    
    public static func setSocketNoSigPipe(_ socket: Int32) throws {
        var value = 1
        if Darwin.setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &value, socklen_t(MemoryLayout<Int32>.size)) == -1 {
            throw SwifterError.setNoSigPipeFailed(Process.error)
        }
    }
}

public class KernelQueue {
    
    private var events = Array<kevent>(repeating: kevent(), count: 256)
    private var changes = Array<kevent>()
    
    private let queue: Int32
    
    public enum Subscription { case read, write }
    public enum Event { case read, write, error }
    
    public init() throws {
        guard case let queue = kqueue(), queue != -1 else {
            throw SwifterError.async(Process.error)
        }
        self.queue = queue
    }
    
    public func subscribe(_ ident: UInt, _ event: Subscription) {
        switch event {
        case .read  : changes.append(self.event(UInt(ident), Int16(EVFILT_READ), UInt16(EV_ADD) | UInt16(EV_ENABLE)))
        case .write : changes.append(self.event(UInt(ident), Int16(EVFILT_WRITE), UInt16(EV_ADD) | UInt16(EV_ENABLE)))
        }
    }
    
    public func unsubscribe(_ ident: UInt, _ event: Subscription) {
        switch event {
        case .read  : changes.append(self.event(UInt(ident), Int16(EVFILT_READ), UInt16(EV_DELETE)))
        case .write : changes.append(self.event(UInt(ident), Int16(EVFILT_WRITE), UInt16(EV_DELETE)))
        }
    }
    
    public func pause(_ ident: UInt, _ event: Subscription) {
        switch event {
        case .read  : changes.append(self.event(UInt(ident), Int16(EVFILT_READ), UInt16(EV_DISABLE)))
        case .write : changes.append(self.event(UInt(ident), Int16(EVFILT_WRITE), UInt16(EV_DISABLE)))
        }
    }
    
    public func resume(_ ident: UInt, _ event: Subscription) {
        switch event {
        case .read  : changes.append(self.event(UInt(ident), Int16(EVFILT_READ), UInt16(EV_ENABLE)))
        case .write : changes.append(self.event(UInt(ident), Int16(EVFILT_WRITE), UInt16(EV_ENABLE)))
        }
    }
    
    private func event(_ ident: UInt, _ filter: Int16, _ flags: UInt16) -> kevent {
        return kevent(ident: ident, filter: filter, flags: flags, fflags: 0, data: 0, udata: nil)
    }
    
    public func wait(_ callback: (_ tuple: (event: Event, ident: UInt, data: Int)) throws -> (Void)) throws {
        
        if !changes.isEmpty {
            if kevent(self.queue, &changes, Int32(changes.count), nil, 0, nil) == -1 {
                throw SwifterError.async(Process.error)
            }
        }
        
        self.changes.removeAll(keepingCapacity: true)
        
        guard case let count = kevent(self.queue, nil, 0, &events, Int32(events.count), nil), count != -1 else {
            throw SwifterError.async(Process.error)
        }
        
        for event in events[0..<Int(count)] {
            
            if Int32(event.flags) & EV_EOF != 0 || Int32(event.flags) & EV_ERROR != 0 {
                try callback((.error, event.ident, 0))
                continue
            }
            if Int32(event.filter) == EVFILT_READ {
                try callback((.read, event.ident, event.data))
                continue
            }
            if Int32(event.filter) == EVFILT_WRITE {
                try callback((.write, event.ident, event.data))
                continue
            }
        }
    }
}
    
#endif

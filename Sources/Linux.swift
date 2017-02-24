//
//  Linux.swift
//  Swifter
//
//  Copyright © 2016 kolakowski. All rights reserved.
//

#if os(Linux)
    
import Glibc

public class LinuxIO: IO {
    
    private var backlog = [Int32: Array<(chunk: [UInt8], done: ((Void) -> IODoneAction))>]()
    
    private var descriptors = [pollfd]()
    
    private let server: Int32
    
    public required init(_ port: in_port_t, forceIPv4: Bool, bindAddress: String? = nil) throws {
        
        self.server = try LinuxIO.nonBlockingSocketForListenening(port, forceIPv4: forceIPv4, address: bindAddress)
        
        self.descriptors.append(pollfd(fd: self.server, events: Int16(POLLIN), revents: 0))
    }
    
    deinit {
        cleanup()
    }
    
    public func write(_ socket: Int32, _ data: Array<UInt8>, _ done: @escaping ((Void) -> IODoneAction)) throws {
        let result = Glibc.write(socket, data, data.count)
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
        let leftData = [UInt8](data[result..<data.count])
        for i in 0..<descriptors.count {
            if descriptors[i].fd == socket {
                self.backlog[socket]?.append((leftData, done))
                descriptors[i].events = descriptors[i].events | Int16(POLLOUT)
                return
            }
        }
    }
    
    public func wait(_ callback: ((IOEvent) -> Void)) throws {
        guard poll(&descriptors, UInt(descriptors.count), -1) != -1 else {
            throw SwifterError.async(Process.error)
        }
        for i in 0..<descriptors.count {
            if descriptors[i].revents == 0 {
                continue
            }
            if descriptors[i].fd == server {
                while case let client = accept(server, nil, nil), client > 0 {
                    try LinuxIO.setSocketNonBlocking(client)
                    self.backlog[Int32(client)] = []
                    descriptors.append(pollfd(fd: client, events: Int16(POLLIN), revents: 0))
                    callback(IOEvent.connect("", Int32(client)))
                }
                if errno != EWOULDBLOCK { throw SwifterError.acceptFailed(Process.error) }
            } else {
                if (descriptors[i].revents & Int16(POLLERR) != 0) || (descriptors[i].revents & Int16(POLLHUP) != 0) || (descriptors[i].revents & Int16(POLLNVAL) != 0) {
                    self.finish(descriptors[i].fd)
                    callback(IOEvent.disconnect("", descriptors[i].fd))
                    descriptors[i].fd = -1
                    continue
                }
                if descriptors[i].revents & Int16(POLLIN) != 0 {
                    var buffer = [UInt8](repeating: 0, count: 256)
                    readLoop: while true {
                        let result = read(descriptors[i].fd, &buffer, 256)
                        switch result {
                        case -1:
                            if errno != EWOULDBLOCK {
                                callback(IOEvent.disconnect("", descriptors[i].fd))
                                self.finish(descriptors[i].fd)
                                descriptors[i].fd = -1
                            }
                            break readLoop
                        case 0:
                            callback(IOEvent.disconnect("", descriptors[i].fd))
                            self.finish(descriptors[i].fd)
                            descriptors[i].fd = -1
                            break readLoop
                        default:
                            callback(IOEvent.data("", descriptors[i].fd, buffer[0..<result]))
                        }
                    }
                }
                if descriptors[i].revents & Int16(POLLOUT) != 0 {
                    while let backlogElement = self.backlog[Int32(descriptors[i].fd)]?.first {
                        var chunk = backlogElement.chunk
                        let result = Glibc.write(Int32(descriptors[i].fd), chunk, chunk.count)
                        if result == -1 {
                            finish(Int32(descriptors[i].fd))
                            callback(IOEvent.disconnect("", Int32(descriptors[i].fd)))
                            descriptors[i].fd = -1
                            return
                        }
                        if result < chunk.count {
                            let leftData = [UInt8](chunk[result..<chunk.count])
                            self.backlog[Int32(descriptors[i].fd)]?.remove(at: 0)
                            self.backlog[Int32(descriptors[i].fd)]?.insert((chunk: leftData, done: backlogElement.done), at: 0)
                            return
                        }
                        self.backlog[Int32(descriptors[i].fd)]?.removeFirst()
                        if backlogElement.done() == .terminate {
                            finish(Int32(descriptors[i].fd))
                            callback(IOEvent.disconnect("", Int32(descriptors[i].fd)))
                            descriptors[i].fd = -1
                            return
                        }
                    }
                    descriptors[i].events = descriptors[i].events & (~Int16(POLLOUT))
                }
            }
        }
        for i in (0..<descriptors.count).reversed() {
            if descriptors[i].fd == -1 {
                descriptors.remove(at: i)
            }
        }
    }
    
    public func finish(_ socket: Int32) {
        self.backlog[socket] = []
        let _ = Glibc.close(socket)
    }
    
    public func cleanup() {
        for client in self.descriptors {
            let _ = Glibc.close(client.fd)
        }
        let _ = Glibc.close(Int32(server))
    }
    
    public static func nonBlockingSocketForListenening(_ port: in_port_t = 8080, forceIPv4: Bool = false, address: String? = nil) throws -> Int32 {
        
        let server = Glibc.socket(forceIPv4 ? AF_INET : AF_INET6, Int32(SOCK_STREAM.rawValue), 0)
        
        guard server != -1 else {
            throw SwifterError.socketCreation(Process.error)
        }
        
        var value: Int32 = 1
        if Glibc.setsockopt(server, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(MemoryLayout<Int32>.size)) == -1 {
            defer { let _ = Glibc.close(server) }
            throw SwifterError.setReuseAddrFailed(Process.error)
        }
        
        do {
            try setSocketNonBlocking(server)
            if forceIPv4 {
                try bind(toSocket: server, port: port, andIPv4Address: address)
            } else {
                try bind(toSocket: server, port: port, andAddress: address)
            }
        } catch {
            let _ = Glibc.close(server)
            throw error
        }
        
        if Glibc.listen(server, SOMAXCONN) == -1 {
            defer { let _ = Glibc.close(server) }
            throw SwifterError.listenFailed(Process.error)
        }
        
        return server
    }
    
    public static func bind(toSocket socket: Int32, port: in_port_t, andIPv4Address address: String? = nil) throws  {
        
        var addr = sockaddr_in()
        
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
            Glibc.bind(socket, UnsafePointer<sockaddr>(OpaquePointer($0)), socklen_t(MemoryLayout<sockaddr_in>.size))
        }
        
        guard bindResult != -1 else {
            throw SwifterError.bindFailed(Errno.description())
        }
    }
    
    public static func bind(toSocket socket: Int32, port: in_port_t, andAddress address: String? = nil) throws {
        
        var addr = sockaddr_in6()
        
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
            Glibc.bind(socket, UnsafePointer<sockaddr>(OpaquePointer($0)), socklen_t(MemoryLayout<sockaddr_in6>.size))
        }
        
        guard bindResult != -1 else {
            throw SwifterError.bindFailed(Errno.description())
        }
    }

    public static func setSocketNonBlocking(_ socket: Int32) throws {
        if Glibc.fcntl(socket, F_SETFL, fcntl(socket, F_GETFL, 0) | O_NONBLOCK) == -1 {
            throw SwifterError.setNonBlockFailed(Process.error)
        }
    }
}
    
#endif

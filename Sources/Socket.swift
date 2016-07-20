//
//  Socket.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

/* Low level routines for POSIX sockets */

public enum SocketError: ErrorType {
    case SocketCreationFailed(String)
    case SocketSettingReUseAddrFailed(String)
    case BindFailed(String)
    case ListenFailed(String)
    case WriteFailed(String)
    case GetPeerNameFailed(String)
    case ConvertingPeerNameFailed
    case GetNameInfoFailed(String)
    case AcceptFailed(String)
    case RecvFailed(String)
    case GetSockNameFailed(String)
}

public class Socket: Hashable, Equatable {
    
    public class func tcpSocketForListen(port: in_port_t, forceIPv4: Bool = false, maxPendingConnection: Int32 = SOMAXCONN) throws -> Socket {
        
        #if os(Linux)
            let socketFileDescriptor = socket(forceIPv4 ? AF_INET : AF_INET6, Int32(SOCK_STREAM.rawValue), 0)
        #else
            let socketFileDescriptor = socket(forceIPv4 ? AF_INET : AF_INET6, SOCK_STREAM, 0)
        #endif
        
        if socketFileDescriptor == -1 {
            throw SocketError.SocketCreationFailed(Errno.description())
        }
        
        var value: Int32 = 1
        if setsockopt(socketFileDescriptor, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(sizeof(Int32))) == -1 {
            let details = Errno.description()
            Socket.release(socketFileDescriptor)
            throw SocketError.SocketSettingReUseAddrFailed(details)
        }
        Socket.setNoSigPipe(socketFileDescriptor)
        
        #if os(Linux)
            var bindResult: Int32 = -1
            if forceIPv4 {
                var addr = sockaddr_in(sin_family: sa_family_t(AF_INET),
                    sin_port: port.bigEndian,
                    sin_addr: in_addr(s_addr: in_addr_t(0)),
                    sin_zero:(0, 0, 0, 0, 0, 0, 0, 0))
                
                bindResult = withUnsafePointer(&addr) { bind(socketFileDescriptor, UnsafePointer<sockaddr>($0), socklen_t(sizeof(sockaddr_in))) }
            } else {
                var addr = sockaddr_in6(sin6_family: sa_family_t(AF_INET6),
                    sin6_port: port.bigEndian,
                    sin6_flowinfo: 0,
                    sin6_addr: in6addr_any,
                    sin6_scope_id: 0)
                
                bindResult = withUnsafePointer(&addr) { bind(socketFileDescriptor, UnsafePointer<sockaddr>($0), socklen_t(sizeof(sockaddr_in6))) }
            }
        #else
            var bindResult: Int32 = -1
            if forceIPv4 {
                var addr = sockaddr_in(sin_len: UInt8(strideof(sockaddr_in)),
                    sin_family: UInt8(AF_INET),
                    sin_port: port.bigEndian,
                    sin_addr: in_addr(s_addr: in_addr_t(0)),
                    sin_zero:(0, 0, 0, 0, 0, 0, 0, 0))
             
                bindResult = withUnsafePointer(&addr) { bind(socketFileDescriptor, UnsafePointer<sockaddr>($0), socklen_t(sizeof(sockaddr_in))) }
            } else {
                var addr = sockaddr_in6(sin6_len: UInt8(strideof(sockaddr_in6)),
                    sin6_family: UInt8(AF_INET6),
                    sin6_port: port.bigEndian,
                    sin6_flowinfo: 0,
                    sin6_addr: in6addr_any,
                    sin6_scope_id: 0)
                
                bindResult = withUnsafePointer(&addr) { bind(socketFileDescriptor, UnsafePointer<sockaddr>($0), socklen_t(sizeof(sockaddr_in6))) }
            }
        #endif

        if bindResult == -1 {
            let details = Errno.description()
            Socket.release(socketFileDescriptor)
            throw SocketError.BindFailed(details)
        }
        
        if listen(socketFileDescriptor, maxPendingConnection ) == -1 {
            let details = Errno.description()
            Socket.release(socketFileDescriptor)
            throw SocketError.ListenFailed(details)
        }
        return Socket(socketFileDescriptor: socketFileDescriptor)
    }
    
    let socketFileDescriptor: Int32
    
    public init(socketFileDescriptor: Int32) {
        self.socketFileDescriptor = socketFileDescriptor
    }
    
    deinit {
        shutdwn()
    }
    
    public var hashValue: Int { return Int(self.socketFileDescriptor) }
    
    public func release() {
        Socket.release(self.socketFileDescriptor)
    }
    
    public func shutdwn() {
        Socket.shutdwn(self.socketFileDescriptor)
    }
    
    public func acceptClientSocket() throws -> Socket {
        var addr = sockaddr()        
        var len: socklen_t = 0
        let clientSocket = accept(self.socketFileDescriptor, &addr, &len)
        if clientSocket == -1 {
            throw SocketError.AcceptFailed(Errno.description())
        }
        Socket.setNoSigPipe(clientSocket)
        return Socket(socketFileDescriptor: clientSocket)
    }
    
    public func port() throws -> in_port_t {
        var addr = sockaddr_in()
        return try withUnsafePointer(&addr) { pointer in
            var len = socklen_t(sizeof(sockaddr_in))
            if getsockname(socketFileDescriptor, UnsafeMutablePointer(pointer), &len) != 0 {
                throw SocketError.GetSockNameFailed(Errno.description())
            }
            #if os(Linux)
                return ntohs(addr.sin_port)
            #else
                return Int(OSHostByteOrder()) == OSLittleEndian ? addr.sin_port.littleEndian : addr.sin_port.bigEndian
            #endif
        }
    }
    
    public func writeUTF8(string: String) throws {
        try writeUInt8(ArraySlice(string.utf8))
    }
    
    public func writeUInt8(data: [UInt8]) throws {
        try writeUInt8(ArraySlice(data))
    }
    
    public func writeUInt8(data: ArraySlice<UInt8>) throws {
        try data.withUnsafeBufferPointer {
            var sent = 0
            while sent < data.count {
                #if os(Linux)
                    let s = send(self.socketFileDescriptor, $0.baseAddress + sent, Int(data.count - sent), Int32(MSG_NOSIGNAL))
                #else
                    let s = write(self.socketFileDescriptor, $0.baseAddress + sent, Int(data.count - sent))
                #endif
                if s <= 0 {
                    throw SocketError.WriteFailed(Errno.description())
                }
                sent += s
            }
        }
    }
    
    public func read() throws -> UInt8 {
        var buffer = [UInt8](count: 1, repeatedValue: 0)
        let next = recv(self.socketFileDescriptor as Int32, &buffer, Int(buffer.count), 0)
        if next <= 0 {
            throw SocketError.RecvFailed(Errno.description())
        }
        return buffer[0]
    }
    
    private static let CR = UInt8(13)
    private static let NL = UInt8(10)
    
    public func readLine() throws -> String {
        var characters: String = ""
        var n: UInt8 = 0
        repeat {
            n = try self.read()
            if n > Socket.CR { characters.append(Character(UnicodeScalar(n))) }
        } while n != Socket.NL
        return characters
    }
    
    public func peername() throws -> String {
        var addr = sockaddr(), len: socklen_t = socklen_t(sizeof(sockaddr))
        if getpeername(self.socketFileDescriptor, &addr, &len) != 0 {
            throw SocketError.GetPeerNameFailed(Errno.description())
        }
        var hostBuffer = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
        if getnameinfo(&addr, len, &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST) != 0 {
            throw SocketError.GetNameInfoFailed(Errno.description())
        }
        guard let name = String.fromCString(hostBuffer) else {
            throw SocketError.ConvertingPeerNameFailed
        }
        return name
    }
    
    private class func setNoSigPipe(socket: Int32) {
        #if os(Linux)
            // There is no SO_NOSIGPIPE in Linux (nor some other systems). You can instead use the MSG_NOSIGNAL flag when calling send(),
            // or use signal(SIGPIPE, SIG_IGN) to make your entire application ignore SIGPIPE.
        #else
            // Prevents crashes when blocking calls are pending and the app is paused ( via Home button ).
            var no_sig_pipe: Int32 = 1
            setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(sizeof(Int32)))
        #endif
    }
    
    private class func shutdwn(socket: Int32) {
        #if os(Linux)
            shutdown(socket, Int32(SHUT_RDWR))
        #else
            Darwin.shutdown(socket, SHUT_RDWR)
        #endif
    }
    
    private class func release(socket: Int32) {
        #if os(Linux)
            shutdown(socket, Int32(SHUT_RDWR))
        #else
            Darwin.shutdown(socket, SHUT_RDWR)
        #endif
        close(socket)
    }
}

public func == (socket1: Socket, socket2: Socket) -> Bool {
    return socket1.socketFileDescriptor == socket2.socketFileDescriptor
}

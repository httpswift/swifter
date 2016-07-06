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

public enum SocketError: ErrorProtocol {
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
}

public class Socket: Hashable, Equatable {
    
    public class func tcpSocketForListen(_ port: in_port_t, forceIPv4: Bool = false, maxPendingConnection: Int32 = SOMAXCONN) throws -> Socket {

        #if os(Linux)
            let socketFileDescriptor = socket(forceIPv4 ? AF_INET : AF_INET6, Int32(SOCK_STREAM.rawValue), 0)
        #else
            let socketFileDescriptor = socket(forceIPv4 ? AF_INET : AF_INET6, SOCK_STREAM, 0)
        #endif
        
        if socketFileDescriptor == -1 {
            throw SocketError.SocketCreationFailed(Socket.descriptionOfLastError())
        }
        
        var value: Int32 = 1
        if setsockopt(socketFileDescriptor, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(sizeof(Int32.self))) == -1 {
            let details = Socket.descriptionOfLastError()
            Socket.release(socketFileDescriptor)
            throw SocketError.SocketSettingReUseAddrFailed(details)
        }
        Socket.setNoSigPipe(socketFileDescriptor)
        
        #if os(Linux)
            var bindResult: Int32 = -1
            if forceIPv4 {
                var addr = sockaddr_in(sin_family: sa_family_t(AF_INET),
                    sin_port: Socket.htonsPort(port),
                    sin_addr: in_addr(s_addr: in_addr_t(0)),
                    sin_zero:(0, 0, 0, 0, 0, 0, 0, 0))
                
                bindResult = withUnsafePointer(&addr) { bind(socketFileDescriptor, UnsafePointer<sockaddr>($0), socklen_t(sizeof(sockaddr_in))) }
            } else {
                var addr = sockaddr_in6(sin6_family: sa_family_t(AF_INET6),
                    sin6_port: Socket.htonsPort(port),
                    sin6_flowinfo: 0,
                    sin6_addr: in6addr_any,
                    sin6_scope_id: 0)
                
                bindResult = withUnsafePointer(&addr) { bind(socketFileDescriptor, UnsafePointer<sockaddr>($0), socklen_t(sizeof(sockaddr_in6))) }
            }
        #else
            var bindResult: Int32 = -1
            if forceIPv4 {
                var addr = sockaddr_in(sin_len: UInt8(strideof(sockaddr_in.self)),
                    sin_family: UInt8(AF_INET),
                    sin_port: Socket.htonsPort(port),
                    sin_addr: in_addr(s_addr: in_addr_t(0)),
                    sin_zero:(0, 0, 0, 0, 0, 0, 0, 0))
             
                bindResult = withUnsafePointer(&addr) { bind(socketFileDescriptor, UnsafePointer<sockaddr>($0), socklen_t(sizeof(sockaddr_in.self))) }
            } else {
                // “Apple recommends always making an IPv6 socket to listen on.  The OS will automatically
                // “downgrade” it to an IPv4 socket if necessary, so there is no need to listen on two different sockets”.
                var addr = sockaddr_in6(sin6_len: UInt8(strideof(sockaddr_in6.self)),
                    sin6_family: UInt8(AF_INET6),
                    sin6_port: Socket.htonsPort(port),
                    sin6_flowinfo: 0,
                    sin6_addr: in6addr_any,
                    sin6_scope_id: 0)
                
                bindResult = withUnsafePointer(&addr) { bind(socketFileDescriptor, UnsafePointer<sockaddr>($0), socklen_t(sizeof(sockaddr_in6.self))) }
            }
        #endif

        if bindResult == -1 {
            let details = Socket.descriptionOfLastError()
            Socket.release(socketFileDescriptor)
            throw SocketError.BindFailed(details)
        }
        
        if listen(socketFileDescriptor, maxPendingConnection ) == -1 {
            let details = Socket.descriptionOfLastError()
            Socket.release(socketFileDescriptor)
            throw SocketError.ListenFailed(details)
        }
        return Socket(socketFileDescriptor: socketFileDescriptor)
    }
    
    internal let socketFileDescriptor: Int32
    
    public init(socketFileDescriptor: Int32) {
        self.socketFileDescriptor = socketFileDescriptor
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
            throw SocketError.AcceptFailed(Socket.descriptionOfLastError())
        }
        Socket.setNoSigPipe(clientSocket)
        return Socket(socketFileDescriptor: clientSocket)
    }
    
    public func writeUTF8(_ string: String) throws {
        try writeUInt8(ArraySlice(string.utf8))
    }
    
    public func writeUInt8(_ data: [UInt8]) throws {
        try writeUInt8(ArraySlice(data))
    }
    
    public func writeUInt8(_ data: ArraySlice<UInt8>) throws {
        try data.withUnsafeBufferPointer {
            guard let baseAddress = $0.baseAddress else {
                throw SocketError.WriteFailed("The base address of data slice is nil.")
            }
            var sent = 0
            while sent < data.count {
                #if os(Linux)
                    let s = send(self.socketFileDescriptor, baseAddress + sent, Int(data.count - sent), Int32(MSG_NOSIGNAL))
                #else
                    let s = write(self.socketFileDescriptor, baseAddress + sent, Int(data.count - sent))
                #endif
                if s <= 0 {
                    throw SocketError.WriteFailed(Socket.descriptionOfLastError())
                }
                sent += s
            }
        }
    }
    
    public func read() throws -> UInt8 {
        var buffer = [UInt8](repeating: 0, count: 1)
        let next = recv(self.socketFileDescriptor as Int32, &buffer, Int(buffer.count), 0)
        if next <= 0 {
            throw SocketError.RecvFailed(Socket.descriptionOfLastError())
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
        var addr = sockaddr(), len: socklen_t = socklen_t(sizeof(sockaddr.self))
        if getpeername(self.socketFileDescriptor, &addr, &len) != 0 {
            throw SocketError.GetPeerNameFailed(Socket.descriptionOfLastError())
        }
        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        if getnameinfo(&addr, len, &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST) != 0 {
            throw SocketError.GetNameInfoFailed(Socket.descriptionOfLastError())
        }
        return String(cString: hostBuffer)
    }
    
    private class func descriptionOfLastError() -> String {
        return String(cString: UnsafePointer(strerror(errno))) ?? "Error: \(errno)"
    }
    
    private class func setNoSigPipe(_ socket: Int32) {
        #if os(Linux)
            // There is no SO_NOSIGPIPE in Linux (nor some other systems). You can instead use the MSG_NOSIGNAL flag when calling send(),
            // or use signal(SIGPIPE, SIG_IGN) to make your entire application ignore SIGPIPE.
        #else
            // Prevents crashes when blocking calls are pending and the app is paused ( via Home button ).
            var no_sig_pipe: Int32 = 1
            setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(sizeof(Int32.self)))
        #endif
    }
    
    private class func shutdwn(_ socket: Int32) {
        #if os(Linux)
            shutdown(socket, Int32(SHUT_RDWR))
        #else
            let _ = Darwin.shutdown(socket, SHUT_RDWR)
        #endif
    }
    
    private class func release(_ socket: Int32) {
        #if os(Linux)
            shutdown(socket, Int32(SHUT_RDWR))
            close(socket)
        #else
            if Darwin.shutdown(socket, SHUT_RDWR) != -1 {
                // If you close socket which was already closed it produces exception visible in TestFlight's crash log.
                // This is easily can be fixed by checking result on shutdown function != -1.
                close(socket)
            }
        #endif
    }
    
    private class func htonsPort(_ port: in_port_t) -> in_port_t {
        #if os(Linux)
            return htons(port)
        #else
            let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
            return isLittleEndian ? _OSSwapInt16(port) : port
        #endif
    }
}

public func ==(socket1: Socket, socket2: Socket) -> Bool {
    return socket1.socketFileDescriptor == socket2.socketFileDescriptor
}

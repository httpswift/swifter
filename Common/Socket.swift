//
//  Socket.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

/* Low level routines for POSIX sockets */

enum SocketError: ErrorType {
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

public class Socket : Hashable {
    
    public class func tcpSocketForListen(port: in_port_t = 8080, maxPendingConnection: Int32 = SOMAXCONN) throws -> Socket {
        let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
        if socketFileDescriptor == -1 {
            throw SocketError.SocketCreationFailed(Socket.descriptionOfLastError())
        }
        
        var value: Int32 = 1
        if setsockopt(socketFileDescriptor, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(sizeof(Int32))) == -1 {
            let details = Socket.descriptionOfLastError()
            Socket.release(socketFileDescriptor)
            throw SocketError.SocketSettingReUseAddrFailed(details)
        }
        Socket.setNoSigPipe(socketFileDescriptor)
        
        var addr = sockaddr_in(
            sin_len: __uint8_t(sizeof(sockaddr_in)),
            sin_family: sa_family_t(AF_INET),
            sin_port: Socket.htonsPort(port),
            sin_addr: in_addr(s_addr: inet_addr("0.0.0.0")),
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        var sock_addr = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
        memcpy(&sock_addr, &addr, Int(sizeof(sockaddr_in)))
        
        if bind(socketFileDescriptor, &sock_addr, socklen_t(sizeof(sockaddr_in))) == -1 {
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
    
    private let socketFileDescriptor: CInt
    
    init(socketFileDescriptor: CInt) {
        self.socketFileDescriptor = socketFileDescriptor
    }
    
    public var hashValue: Int { return Int(self.socketFileDescriptor) }
    
    public func release() {
        Socket.release(self.socketFileDescriptor)
    }
    
    public func shutdown() {
        Socket.shutdown(self.socketFileDescriptor)
    }
    
    public func acceptClientSocket() throws -> Socket {
        var addr = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
        var len: socklen_t = 0
        let clientSocket = accept(self.socketFileDescriptor, &addr, &len)
        if clientSocket == -1 {
            throw SocketError.AcceptFailed(Socket.descriptionOfLastError())
        }
        Socket.setNoSigPipe(clientSocket)
        return Socket(socketFileDescriptor: clientSocket)
    }
    
    public func writeUTF8(string: String) throws {
        try self.writeString(string, withEncoding: NSUTF8StringEncoding)
    }
    
    public func writeASCII(string: String) throws {
        try self.writeString(string, withEncoding: NSASCIIStringEncoding)
    }
    
    public func writeString(string: String, withEncoding encoding: NSStringEncoding) throws {
        if let nsdata = string.dataUsingEncoding(encoding) {
            try self.writeData(nsdata)
        } else {
            throw SocketError.WriteFailed("dataUsingEncoding(\(encoding)) failed")
        }
    }
    
    public func writeData(data: NSData) throws {
        var sent = 0
        let unsafePointer = UnsafePointer<UInt8>(data.bytes)
        while sent < data.length {
            let s = write(self.socketFileDescriptor, unsafePointer + sent, Int(data.length - sent))
            if s <= 0 {
                throw SocketError.WriteFailed(Socket.descriptionOfLastError())
            }
            sent += s
        }
    }
    
    public func read() -> Int {
        var buffer = [UInt8](count: 1, repeatedValue: 0);
        let next = recv(self.socketFileDescriptor as Int32, &buffer, Int(buffer.count), 0)
        if next <= 0 {
            return next
        }
        return Int(buffer[0])
    }
    
    public func readLine() throws -> String {
        var characters: String = ""
        var n = 0
        repeat {
            n = self.read()
            if ( n > 13 /* CR */ ) { characters.append(Character(UnicodeScalar(n))) }
        } while n > 0 && n != 10 /* NL */
        if n == -1 {
            throw SocketError.RecvFailed(Socket.descriptionOfLastError())
        }
        return characters
    }
    
    public func peername() throws -> String {
        var addr = sockaddr(), len: socklen_t = socklen_t(sizeof(sockaddr))
        if getpeername(self.socketFileDescriptor, &addr, &len) != 0 {
            throw SocketError.GetPeerNameFailed(Socket.descriptionOfLastError())
        }
        var hostBuffer = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
        if getnameinfo(&addr, len, &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST) != 0 {
            throw SocketError.GetNameInfoFailed(Socket.descriptionOfLastError())
        }
        guard let name = String.fromCString(hostBuffer) else {
            throw SocketError.ConvertingPeerNameFailed
        }
        return name
    }
    
    private class func descriptionOfLastError() -> String {
        return String.fromCString(UnsafePointer(strerror(errno))) ?? "Error: \(errno)"
    }
    
    private class func setNoSigPipe(socket: CInt) {
        // prevents crashes when blocking calls are pending and the app is paused ( via Home button )
        var no_sig_pipe: Int32 = 1;
        setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(sizeof(Int32)));
    }
    
    private class func shutdown(socket: CInt) {
        Darwin.shutdown(socket, SHUT_RDWR)
    }
    
    private class func release(socket: CInt) {
        Darwin.shutdown(socket, SHUT_RDWR)
        close(socket)
    }
    
    private class func htonsPort(port: in_port_t) -> in_port_t {
        let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
        return isLittleEndian ? _OSSwapInt16(port) : port
    }
}


public func ==(socket1: Socket, socket2: Socket) -> Bool {
    return socket1.hashValue == socket2.hashValue
}
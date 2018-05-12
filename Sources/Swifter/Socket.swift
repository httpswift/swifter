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

public enum SocketError: Error {
    case socketCreationFailed(String)
    case socketSettingReUseAddrFailed(String)
    case bindFailed(String)
    case listenFailed(String)
    case writeFailed(String)
    case getPeerNameFailed(String)
    case convertingPeerNameFailed
    case getNameInfoFailed(String)
    case acceptFailed(String)
    case recvFailed(String)
    case getSockNameFailed(String)
}

public class Socket: Hashable, Equatable {
    
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
    
    public func port() throws -> in_port_t {
        var addr = sockaddr_in()
        let addr_copy = addr
        return try withUnsafePointer(to: &addr) { pointer in
            var len = socklen_t(MemoryLayout<sockaddr_in>.size)
            if getsockname(socketFileDescriptor, UnsafeMutablePointer(OpaquePointer(pointer)), &len) != 0 {
                throw SocketError.getSockNameFailed(Process.lastErrno)
            }
            #if os(Linux)
                return ntohs(addr_copy.sin_port)
            #else
                return Int(OSHostByteOrder()) != OSLittleEndian ? addr_copy.sin_port.littleEndian : addr_copy.sin_port.bigEndian
            #endif
        }
    }
    
    public func isIPv4() throws -> Bool {
        var addr = sockaddr_in()
        let addr_copy = addr
        return try withUnsafePointer(to: &addr) { pointer in
            var len = socklen_t(MemoryLayout<sockaddr_in>.size)
            if getsockname(socketFileDescriptor, UnsafeMutablePointer(OpaquePointer(pointer)), &len) != 0 {
                throw SocketError.getSockNameFailed(Process.lastErrno)
            }
            return Int32(addr_copy.sin_family) == AF_INET
        }
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
                throw SocketError.writeFailed("The base address of data slice is nil.")
            }
            var sent = 0
            while sent < data.count {
                #if os(Linux)
                    let s = send(self.socketFileDescriptor, baseAddress + sent, Int(data.count - sent), Int32(MSG_NOSIGNAL))
                #else
                    let s = write(self.socketFileDescriptor, baseAddress + sent, Int(data.count - sent))
                #endif
                if s <= 0 {
                    throw SocketError.writeFailed(Process.lastErrno)
                }
                sent += s
            }
        }
    }
    
    public func read() throws -> UInt8 {
        var buffer = [UInt8](repeating: 0, count: 1)
        let next = recv(self.socketFileDescriptor as Int32, &buffer, Int(buffer.count), 0)
        if next <= 0 {
            throw SocketError.recvFailed(Process.lastErrno)
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
        var addr = sockaddr(), len: socklen_t = socklen_t(MemoryLayout<sockaddr>.size)
        if getpeername(self.socketFileDescriptor, &addr, &len) != 0 {
            throw SocketError.getPeerNameFailed(Process.lastErrno)
        }
        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        if getnameinfo(&addr, len, &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST) != 0 {
            throw SocketError.getNameInfoFailed(Process.lastErrno)
        }
        return String(cString: hostBuffer)
    }
    
    public class func setNoSigPipe(_ socket: Int32) {
        #if os(Linux)
            // There is no SO_NOSIGPIPE in Linux (nor some other systems). You can instead use the MSG_NOSIGNAL flag when calling send(),
            // or use signal(SIGPIPE, SIG_IGN) to make your entire application ignore SIGPIPE.
        #else
            // Prevents crashes when blocking calls are pending and the app is paused ( via Home button ).
            var no_sig_pipe: Int32 = 1
            setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(MemoryLayout<Int32>.size))
        #endif
    }
    
    public class func shutdwn(_ socket: Int32) {
        #if os(Linux)
            shutdown(socket, Int32(SHUT_RDWR))
        #else
            let _ = Darwin.shutdown(socket, SHUT_RDWR)
        #endif
    }
    
    public class func release(_ socket: Int32) {
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
}

public func ==(socket1: Socket, socket2: Socket) -> Bool {
    return socket1.socketFileDescriptor == socket2.socketFileDescriptor
}

//
//  Socket.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

/* Low level routines for POSIX sockets */

enum SocketError: ErrorType {
    case SocketInitializationFailed
    case SocketOptionInitializationFailed
    case BindFailed
    case ListenFailed
    case WriteFailed
    case PeerNameFailed
    case NameInfoFailed
    case AcceptFailed
    
    var message: String {
        switch self {
            case .SocketInitializationFailed:
                return "socket(...) failed"
            
            case .SocketOptionInitializationFailed:
                return "setsockopt(...) failed."
            
            case .BindFailed:
                return "bind(...) failed."
            
            case .ListenFailed:
                return "listen(...) failed."
            
            case .WriteFailed:
                return "write(...) failed"
            
            case .PeerNameFailed:
                return "getpeername(...) failed"
            
            case .NameInfoFailed:
                return "getnameinfo(...) failed"
            
            case .AcceptFailed:
                return "accept(...) failed."
        }
    }
}

let maxPendingConnection: Int32 = 20

struct Socket {    
    static func tcpForListen(port: in_port_t = 8080) throws -> CInt {
        let s = socket(AF_INET, SOCK_STREAM, 0)
        if ( s == -1 ) {
            throw SocketError.SocketInitializationFailed
        }
        var value: Int32 = 1;
        if ( setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(sizeof(Int32))) == -1 ) {
            release(s)
            throw SocketError.SocketOptionInitializationFailed
        }
        nosigpipe(s)
        var addr = sockaddr_in(sin_len: __uint8_t(sizeof(sockaddr_in)),
            sin_family: sa_family_t(AF_INET),
            sin_port: port_htons(port),
            sin_addr: in_addr(s_addr: inet_addr("0.0.0.0")),
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        
        var sock_addr = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
        memcpy(&sock_addr, &addr, Int(sizeof(sockaddr_in)))
        if ( bind(s, &sock_addr, socklen_t(sizeof(sockaddr_in))) == -1 ) {
            release(s)
            throw SocketError.BindFailed
        }
        if ( listen(s, maxPendingConnection ) == -1 ) {
            release(s)
            throw SocketError.ListenFailed
        }
        return s
    }
    
    static func writeUTF8(socket: CInt, string: String) throws {
        if let nsdata = string.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                try writeData(socket, data: nsdata)
            } catch {
                throw error
            }
        }
    }
    
    static func writeASCII(socket: CInt, string: String) throws {
        if let nsdata = string.dataUsingEncoding(NSASCIIStringEncoding) {
            do {
                try writeData(socket, data: nsdata)
            } catch {
                throw error
            }
        }
    }
    
    static func writeData(socket: CInt, data: NSData) throws {
        var sent = 0
        let unsafePointer = UnsafePointer<UInt8>(data.bytes)
        while ( sent < data.length ) {
            let s = write(socket, unsafePointer + sent, Int(data.length - sent))
            if ( s <= 0 ) {
                throw SocketError.WriteFailed
            }
            sent += s
        }
    }
    
    static func acceptClientSocket(socket: CInt) throws -> CInt {
        var addr = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
        var len: socklen_t = 0
        let clientSocket = accept(socket, &addr, &len)
        if ( clientSocket == -1 ) {
            throw SocketError.AcceptFailed
        }
        Socket.nosigpipe(clientSocket)
        return clientSocket
    }
    
    static func nosigpipe(socket: CInt) {
        // prevents crashes when blocking calls are pending and the app is paused ( via Home button )
        var no_sig_pipe: Int32 = 1;
        setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(sizeof(Int32)));
    }
    
    static func port_htons(port: in_port_t) -> in_port_t {
        let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
        return isLittleEndian ? _OSSwapInt16(port) : port
    }
    
    static func release(socket: CInt) {
        shutdown(socket, SHUT_RDWR)
        close(socket)
    }
    
    static func peername(socket: CInt) throws -> String? {
        var addr = sockaddr(), len: socklen_t = socklen_t(sizeof(sockaddr))
        if getpeername(socket, &addr, &len) != 0 {
            throw SocketError.PeerNameFailed
        }
        var hostBuffer = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
        if getnameinfo(&addr, len, &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST) != 0 {
            throw SocketError.NameInfoFailed
        }
        return String.fromCString(hostBuffer)
    }
}

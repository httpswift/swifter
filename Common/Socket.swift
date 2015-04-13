//
//  Socket.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

/* Low level routines for POSIX sockets */

struct Socket {
        
    static func lastErr(reason: String) -> NSError {
        let errorCode = errno
        if let errorText = String.fromCString(UnsafePointer(strerror(errorCode))) {
            return NSError(domain: "SOCKET", code: Int(errorCode), userInfo: [NSLocalizedFailureReasonErrorKey : reason, NSLocalizedDescriptionKey : errorText])
        }
        return NSError(domain: "SOCKET", code: Int(errorCode), userInfo: nil)
    }
    
    static func tcpForListen(port: in_port_t = 8080, error:NSErrorPointer = nil) -> CInt? {
        let s = socket(AF_INET, SOCK_STREAM, 0)
        if ( s == -1 ) {
            if error != nil { error.memory = lastErr("socket(...) failed.") }
            return nil
        }
        var value: Int32 = 1;
        if ( setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(sizeof(Int32))) == -1 ) {
            release(s)
            if error != nil { error.memory = lastErr("setsockopt(...) failed.") }
            return nil
        }
        nosigpipe(s)
        var addr = sockaddr_in(sin_len: __uint8_t(sizeof(sockaddr_in)), sin_family: sa_family_t(AF_INET),
            sin_port: port_htons(port), sin_addr: in_addr(s_addr: inet_addr("0.0.0.0")), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        
        var sock_addr = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
        memcpy(&sock_addr, &addr, Int(sizeof(sockaddr_in)))
        if ( bind(s, &sock_addr, socklen_t(sizeof(sockaddr_in))) == -1 ) {
            release(s)
            if error != nil { error.memory = lastErr("bind(...) failed.") }
            return nil
        }
        if ( listen(s, 20 /* max pending connection */ ) == -1 ) {
            release(s)
            if error != nil { error.memory = lastErr("listen(...) failed.") }
            return nil
        }
        return s
    }
    
    static func writeUTF8(socket: CInt, string: String, error: NSErrorPointer = nil) -> Bool {
        if let nsdata = string.dataUsingEncoding(NSUTF8StringEncoding) {
            writeData(socket, data: nsdata, error: error)
        }
        return true
    }
    
    static func writeASCII(socket: CInt, string: String, error: NSErrorPointer = nil) -> Bool {
        if let nsdata = string.dataUsingEncoding(NSASCIIStringEncoding) {
            writeData(socket, data: nsdata, error: error)
        }
        return true
    }
    
    static func writeData(socket: CInt, data: NSData, error:NSErrorPointer = nil) -> Bool {
        var sent = 0
        let unsafePointer = UnsafePointer<UInt8>(data.bytes)
        while ( sent < data.length ) {
            let s = write(socket, unsafePointer + sent, Int(data.length - sent))
            if ( s <= 0 ) {
                if error != nil { error.memory = lastErr("write(...) failed.") }
                return false
            }
            sent += s
        }
        return true
    }
    
    static func acceptClientSocket(socket: CInt, error:NSErrorPointer = nil) -> CInt? {
        var addr = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)), len: socklen_t = 0
        let clientSocket = accept(socket, &addr, &len)
        if ( clientSocket != -1 ) {
            Socket.nosigpipe(clientSocket)
            return clientSocket
        }
        if error != nil { error.memory = lastErr("accept(...) failed.") }
        return nil
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
}

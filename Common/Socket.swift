//
//  Socket.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

/* Low level routines for POSIX sockets */

enum SocketError: ErrorType {
    case SocketInitializationFailed(String)
    case SocketOptionInitializationFailed(String)
    case BindFailed(String)
    case ListenFailed(String)
    case WriteFailed(String)
    case GetPeerNameFailed(String)
    case ConvertingPeerNameFailed
    case GetNameInfoFailed(String)
    case AcceptFailed(String)
    case RecvFailed(String)

}

let maxPendingConnection: Int32 = 20

class Socket : Hashable {
    let socketId: CInt
    
    var hashValue: Int {
        return Int(self.socketId)
    }
    
    init(port: in_port_t = 8080) throws {
        self.socketId = socket(AF_INET, SOCK_STREAM, 0)
        if self.socketId == -1 {
            throw SocketError.SocketInitializationFailed(ErrorHandle.errorText)
        }
        
        var value: Int32 = 1
        if setsockopt(self.socketId, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(sizeof(Int32))) == -1 {
            let details = ErrorHandle.errorText
//            self.release()
            throw SocketError.SocketOptionInitializationFailed(details)
        }
        
        self.nosigpipe()
        
        var addr = sockaddr_in(sin_len: __uint8_t(sizeof(sockaddr_in)),
                               sin_family: sa_family_t(AF_INET),
                               sin_port: Socket.port_htons(port),
                               sin_addr: in_addr(s_addr: inet_addr("0.0.0.0")),
                               sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        var sock_addr = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
        memcpy(&sock_addr, &addr, Int(sizeof(sockaddr_in)))
        
        if bind(self.socketId, &sock_addr, socklen_t(sizeof(sockaddr_in))) == -1 {
            let details = ErrorHandle.errorText
//            self.release()
            throw SocketError.BindFailed(details)
        }
        
        if listen(self.socketId, maxPendingConnection ) == -1 {
            let details = ErrorHandle.errorText
//            self.release()
            throw SocketError.ListenFailed(details)
        }
    }
    
    private init(socketId: CInt) {
        self.socketId = socketId
    }
    
    deinit {
        print("deinit socket")
        shutdown(self.socketId, SHUT_RDWR)
        close(self.socketId)
    }
    
    func nosigpipe() {
        // prevents crashes when blocking calls are pending and the app is paused ( via Home button )
        var no_sig_pipe: Int32 = 1;
        setsockopt(self.socketId, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(sizeof(Int32)));
    }
    
    class func port_htons(port: in_port_t) -> in_port_t {
        let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
        return isLittleEndian ? _OSSwapInt16(port) : port
    }
    
    
    // MARK: - write methods
    
    func writeUTF8(string: String) throws {
        try self.writeString(string, withEncoding: NSUTF8StringEncoding)
    }
    
    func writeASCII(string: String) throws {
        try self.writeString(string, withEncoding: NSASCIIStringEncoding)
    }
    
    private func writeString(string: String, withEncoding encoding: NSStringEncoding) throws {
        if let nsdata = string.dataUsingEncoding(encoding) {
            try self.writeData(nsdata)
        } else {
            throw SocketError.WriteFailed("dataUsingEncoding(\(encoding)) failed")
        }
    }
    
    func writeData(data: NSData) throws {
        var sent = 0
        let unsafePointer = UnsafePointer<UInt8>(data.bytes)
        while sent < data.length {
            let s = write(self.socketId, unsafePointer + sent, Int(data.length - sent))
            if s <= 0 {
                throw SocketError.WriteFailed(ErrorHandle.errorText)
            }
            sent += s
        }
    }
    
    // MARK: -
    
    func acceptClientSocket() throws -> Socket {
        var addr = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
        var len: socklen_t = 0
        let clientSocket = accept(self.socketId, &addr, &len)
        if clientSocket == -1 {
            throw SocketError.AcceptFailed(ErrorHandle.errorText)
        }
        self.nosigpipe()
        return Socket(socketId: clientSocket)
    }
    
    func peername() throws -> String {
        var addr = sockaddr(), len: socklen_t = socklen_t(sizeof(sockaddr))
        if getpeername(self.socketId, &addr, &len) != 0 {
            throw SocketError.GetPeerNameFailed(ErrorHandle.errorText)
        }
        var hostBuffer = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
        if getnameinfo(&addr, len, &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST) != 0 {
            throw SocketError.GetNameInfoFailed(ErrorHandle.errorText)
        }
        
        guard let name = String.fromCString(hostBuffer) else {
            throw SocketError.ConvertingPeerNameFailed
        }
        
        return name
    }

//    func release() {
//        print("release")
//        shutdown(self.socketId, SHUT_RDWR)
//        close(self.socketId)
//    }
    
    // MARK: - basic receiving
    
    func nextInt8() -> Int {
        var buffer = [UInt8](count: 1, repeatedValue: 0);
        let next = recv(self.socketId as Int32, &buffer, Int(buffer.count), 0)
        if next <= 0 {
            return next
        }
        return Int(buffer[0])
    }
    
    func nextLine() throws -> String {
        var characters: String = ""
        var n = 0
        repeat {
            n = self.nextInt8()
            if ( n > 13 /* CR */ ) { characters.append(Character(UnicodeScalar(n))) }
        } while n > 0 && n != 10 /* NL */
        if n == -1 {
            throw SocketError.RecvFailed(ErrorHandle.errorText)
        }
        return characters
    }
}

func ==(socket1: Socket, socket2: Socket) -> Bool {
    return socket1.socketId == socket2.socketId
}

class ErrorHandle {
    class var errorText: String {
        return String.fromCString(UnsafePointer(strerror(errno))) ?? "error converting error text from C String"
    }
}
//
//  Socket.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//
//  SwifterLite
//  Copyright (c) 2022 Todd Bruss. All rights reserved.
//

import Foundation

open class Socket: Hashable, Equatable {
    
    let socketFileDescriptor: Int32
    static let kBufferLength = 1024
    
    private var shutdown = false
    static let CR: UInt8 = 13
    static let NL: UInt8 = 10
    
    public init(socketFileDescriptor: Int32) {
        self.socketFileDescriptor = socketFileDescriptor
    }
    
    deinit {
        close()
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.socketFileDescriptor)
    }
    
    public func close() {
        Socket.close(self.socketFileDescriptor)
    }
    
    public class func setNoSigPipe(_ socket: Int32) {
        // Prevents crashes when blocking calls are pending and the app is paused ( via Home button ).
        var no_sig_pipe: Int32 = 1
        setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(MemoryLayout<Int32>.size))
    }
    
    public class func close(_ socket: Int32) {
        _ = Darwin.close(socket)
    }
}

public func == (socket1: Socket, socket2: Socket) -> Bool {
    socket1.socketFileDescriptor == socket2.socketFileDescriptor
}

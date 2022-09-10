//
//  SocketClient.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

extension Socket {
    public func acceptClientSocket() throws -> Socket {
        var addr = sockaddr()
        var len: socklen_t = 0
        let clientSocket = accept(self.socketFileDescriptor, &addr, &len)
        
        if clientSocket == -1 {
            throw SocketError.acceptFailed(ErrNumString.description())
        }
        
        Socket.setNoSigPipe(clientSocket)
        
        return Socket(socketFileDescriptor: clientSocket)
    }
}

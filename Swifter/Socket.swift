//
//  Socket.swift
//
//  Created by Damian Kolakowski on 05/06/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

/* Low level routines for POSIX sockets */

struct Socket {
    
    static func tcpForListen(port: in_port_t) -> (CInt, String?) {
        let s = socket(AF_INET, SOCK_STREAM, 0)
        if ( s == -1 ) {
            return (-1, "socket() failed \(errno) - \(strerror(errno))")
        }
        var value: Int32 = 1;
        if ( setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &value, 4) == -1 ) {
            let error = "setsockopt(...) failed \(errno) - \(strerror(errno))"
            release(s)
            return (-1, error)
        }
        nosigpipe(s)
        var addr: sockaddr_in = sockaddr_in(sin_len: sizeof(sockaddr_in).bridgeToObjectiveC().unsignedCharValue,
            sin_family: sa_family_t(AF_INET),
            sin_port: port,
            sin_addr: in_addr(s_addr: inet_addr("0.0.0.0")),
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        
        var sock_addr: sockaddr = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
        memcpy(&sock_addr, &addr, UInt(sizeof(sockaddr_in)))
        if ( bind(s, &sock_addr, sizeof(sockaddr_in).bridgeToObjectiveC().unsignedIntValue) == -1 ) {
            let error = "bind(...) failed \(errno) - \(strerror(errno))"
            release(s)
            return (-1, error)
        }
        if ( listen(s, 20 /* max pending connection */ ) == -1 ) {
            let error = "listen(...) failed \(errno) - \(strerror(errno))"
            release(s)
            return (-1, error)
        }
        return (s, nil)
    }
    
    static func writeString(socket: CInt, response: String) {
        var sent = 0;
        let nsdata = response.bridgeToObjectiveC().dataUsingEncoding(NSUTF8StringEncoding)
        let pointer = nsdata.bytes
        while ( sent < nsdata.length ) {
            // TODO pointer + sent
            let s = write(socket, pointer, UInt(nsdata.length - sent))
            if ( s <= 0 ) {
                return
            }
            sent += s
        }
    }
    
    static func nosigpipe(socket: CInt) {
        // prevents crashes when blocking calls are pending and the app is paused ( via Home button )
        var no_sig_pipe: Int32 = 1;
        setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, 4);
    }
    
    static func release(socket: CInt) {
        shutdown(socket, 2)
        close(socket)
    }
}

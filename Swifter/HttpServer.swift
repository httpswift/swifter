//
//  HttpServer.swift
//
//  Created by Damian Kolakowski on 05/06/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

/* HTTP server */

class HttpServer
{
    var handlers: Dictionary<String, (Void -> (CInt, String))> = Dictionary()
    var acceptSocket: CInt = -1
    
    subscript (path: String) -> ((Void -> (CInt, String))) {
        get {
            return handlers[path]!
        }
        set ( newValue ) {
            self.handlers.updateValue(newValue, forKey: path)
        }
    }
    
    func start(listenPort: in_port_t) -> (Bool, String?) {
        releaseAcceptSocket()
        let (socket, error) = Socket.tcpForListen(listenPort)
        if ( socket == -1 ) {
            return (false, error)
        }
        acceptSocket = socket
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            while ( self.acceptSocket != -1 ) {
                var addr = sockaddr(sa_len: 0, sa_family: 0, sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)), len: socklen_t = 0
                let socket = accept(self.acceptSocket, &addr, &len)
                if ( socket == -1 ) {
                    self.releaseAcceptSocket();
                    return
                }
                Socket.nosigpipe(socket)
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
                    let parser = HttpParser()
                    if let (path, headers) = parser.parseHttpHeader(socket) {
                        if let handler = self.handlers[path] {
                            let (status, response) = handler()
                            // no support for keep-alive for now so let's stay with HTTP 1.0
                            Socket.writeString(socket, response: "HTTP/1.0 \(status)\r\n\r\n\(response)")
                        }
                    }
                    Socket.release(socket)
                });
            }
        });
        return (true, nil)
    }
    
    func stop() {
        releaseAcceptSocket()
    }
    
    func releaseAcceptSocket() {
        if ( acceptSocket != -1 ) {
            Socket.release(acceptSocket)
            acceptSocket = -1
        }
    }
}


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
    enum Statuses {
        static let OK = 200
        static let NOT_FOUND = 404
    }
    
    var handlers: Dictionary<String, (Void -> (Int, String))> = Dictionary()
    var acceptSocket: CInt = -1
    
    subscript (path: String) -> ((Void -> (Int, String))) {
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
                    while let (path, headers) = parser.parseHttpHeader(socket) {
                        if let handler = self.handlers[path] {
                            let (status, response) = handler()
                            Socket.writeStringUTF8(socket, string: "HTTP/1.1 \(status)\r\n")
                            let nsdata = response.bridgeToObjectiveC().dataUsingEncoding(NSUTF8StringEncoding)
                            Socket.writeStringUTF8(socket, string: "Content-Length: \(nsdata.length)\r\n")
                            if parser.supportsKeepAlive(headers) {
                                Socket.writeStringUTF8(socket, string: "Connection: keep-alive\r\n")
                            }
                            Socket.writeStringUTF8(socket, string: "\r\n")
                            Socket.writeStringUTF8(socket, string: response)
                        } else {
                            Socket.writeStringUTF8(socket, string: "HTTP/1.1 \(Statuses.NOT_FOUND)\r\n")
                            Socket.writeStringUTF8(socket, string: "Content-Length: 0\r\n")
                            if parser.supportsKeepAlive(headers) {
                                Socket.writeStringUTF8(socket, string: "Connection: keep-alive\r\n")
                            }
                            Socket.writeStringUTF8(socket, string: "\r\n")
                        }
                        if !parser.supportsKeepAlive(headers) {
                            break
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


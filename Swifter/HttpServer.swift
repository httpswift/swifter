//
//  HttpServer.swift
//
//  Created by Damian Kolakowski on 05/06/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

enum ResponseStatus {
    case OK(String)
    case NotFound

    func numericValue() {
        switch self {
            case .OK(_):
                return 200
            case .NotFound:
                return 404
        }
    }

    func textValue() {
        switch self {
            case .OK(let text):
                return text
            case .NotFound:
                return "Not found"
        }
    }
}

typealias Handler = Void -> ResponseStatus

/* HTTP server */
class HttpServer
{
    var handlers = Dictionary<String, Handler>()
    var acceptSocket: CInt = -1
    
    subscript (path: String) -> Handler {
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
                        let keepAlive = parser.supportsKeepAlive(headers)

                        if let handler = self.handlers[path] {
                            let responseStatus = handler()
                            let responseText = responseStatus.textValue()
                            let nsdata =
                                responseText
                                    .bridgeToObjectiveC()
                                    .dataUsingEncoding(NSUTF8StringEncoding)

                            Socket.writeStringUTF8(socket, string: "HTTP/1.1 \(responseStatus.numericValue())\r\n")
                            Socket.writeStringUTF8(socket, string: "Content-Length: \(nsdata.length)\r\n")
                            if keepAlive {
                                Socket.writeStringUTF8(socket, string: "Connection: keep-alive\r\n")
                            }
                            Socket.writeStringUTF8(socket, string: "\r\n")
                            Socket.writeStringUTF8(socket, string: responseText)
                        } else {
                            Socket.writeStringUTF8(socket, string: "HTTP/1.1 \(ResponseStatus.NotFound.numericValue())\r\n")
                            Socket.writeStringUTF8(socket, string: "Content-Length: 0\r\n")
                            if keepAlive {
                                Socket.writeStringUTF8(socket, string: "Connection: keep-alive\r\n")
                            }
                            Socket.writeStringUTF8(socket, string: "\r\n")
                        }
                        if !keepAlive { break }
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


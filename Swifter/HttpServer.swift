//
//  HttpServer.swift
//
//  Created by Damian Kolakowski on 05/06/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

class HttpServer
{
    typealias Handler = (String, Dictionary<String,String>) -> HttpResponse
    
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
    
    func routes() -> Array<String> {
        var results = Array<String>()
        for (key,_) in handlers { results.append(key) }
        return results
    }
    
    func start(listenPort: in_port_t = 8080, error:NSErrorPointer = nil) -> Bool {
        releaseAcceptSocket()
        if let socket = Socket.tcpForListen(port: listenPort, error: error) {
            acceptSocket = socket
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                while let socket = Socket.acceptClientSocket(self.acceptSocket) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                        let parser = HttpParser()
                        while let (path, method, headers) = parser.nextHttpRequest(socket) {
                            let keepAlive = parser.supportsKeepAlive(headers)
                            if let handler = self.handlers[path] {
                                HttpServer.writeResponse(socket, response: handler(method, headers), keepAlive: keepAlive)
                            } else {
                                HttpServer.writeResponse(socket, response: HttpResponse.NotFound, keepAlive: keepAlive)
                            }
                            if !keepAlive { break }
                        }
                        Socket.release(socket)
                    });
                }
                self.releaseAcceptSocket()
            });
            return true
        }
        return false
    }
    
    class func writeResponse(socket: CInt, response: HttpResponse, keepAlive: Bool) {
        Socket.writeStringUTF8(socket, string: "HTTP/1.1 \(response.statusCode()) \(response.reasonPhrase())\r\n")
        let messageBody = response.body()
        if let body = messageBody {
            let nsdata = body.bridgeToObjectiveC().dataUsingEncoding(NSUTF8StringEncoding)
            Socket.writeStringUTF8(socket, string: "Content-Length: \(nsdata.length)\r\n")
        } else {
            Socket.writeStringUTF8(socket, string: "Content-Length: 0\r\n")
        }
        if keepAlive {
            Socket.writeStringUTF8(socket, string: "Connection: keep-alive\r\n")
        }
        for (name, value) in response.headers() {
            Socket.writeStringUTF8(socket, string: "\(name): \(value)\r\n")
        }
        Socket.writeStringUTF8(socket, string: "\r\n")
        if let body = messageBody {
            Socket.writeStringUTF8(socket, string: body)
        }
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


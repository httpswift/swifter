//
//  HttpServer.swift
//
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

class HttpServer
{
    typealias Handler = HttpRequest -> HttpResponse
    
    var handlers: [(method: String, expression: NSRegularExpression, handler: Handler)] = []
    var acceptSocket: CInt = -1
    
    let matchingOptions = NSMatchingOptions(0)
    let expressionOptions = NSRegularExpressionOptions(0)
    
    subscript (path: String) -> Handler? {
        get {
            return nil
        }
        set ( newValue ) {
            if let regex = NSRegularExpression(pattern: path, options: expressionOptions, error: nil) {
                if let newHandler = newValue {
                    handlers.append(method:"GET",expression: regex, handler: newHandler)
                }
            }
        }
    }
    
    subscript (method: String, path: String) -> Handler? {
        get {
            return nil
        }
        set ( newValue ) {
            if let regex = NSRegularExpression(pattern: path, options: expressionOptions, error: nil) {
                if let newHandler = newValue {
                    handlers.append(method: method, expression: regex, handler: newHandler)
                }
            }
        }
    }
    
    func routes() -> [String] { return map(handlers, { $0.1.pattern }) }
    
    func start(listenPort: in_port_t = 8080, error: NSErrorPointer = nil) -> Bool {
        releaseAcceptSocket()
        if let socket = Socket.tcpForListen(port: listenPort, error: error) {
            acceptSocket = socket
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                while let socket = Socket.acceptClientSocket(self.acceptSocket) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                        let parser = HttpParser()
                        while let request = parser.nextHttpRequest(socket) {
                            let keepAlive = parser.supportsKeepAlive(request.headers)
                            if let (method, expression, handler) = self.findHandler(request.method,url:request.url) {
                                let capturedUrlsGroups = self.captureExpressionGroups(expression, value: request.url)
                                let updatedRequest = HttpRequest(url: request.url, urlParams: request.urlParams, method: request.method, headers: request.headers, body: request.body, capturedUrlGroups: capturedUrlsGroups)
                                HttpServer.writeResponse(socket, response: handler(updatedRequest), keepAlive: keepAlive)
                            } else {
                                HttpServer.writeResponse(socket, response: HttpResponse.NotFound, keepAlive: keepAlive)
                            }
                            if !keepAlive { break }
                        }
                        Socket.release(socket)
                    })
                }
                self.releaseAcceptSocket()
            })
            return true
        }
        return false
    }
    
    func findHandler(method:String,url:String) -> (String, NSRegularExpression, Handler)? {
        return filter(filter(sorted(self.handlers,{ countElements($0.1.pattern) > countElements($1.1.pattern)}),{$0.0 == method}), {
            $0.1.numberOfMatchesInString(url, options: self.matchingOptions, range: HttpServer.asciiRange(url)) > 0
        }).first
    }
    
    func captureExpressionGroups(expression: NSRegularExpression, value: String) -> [String] {
        var capturedGroups = [String]()
        if let result = expression.firstMatchInString(value, options: matchingOptions, range: HttpServer.asciiRange(value)) {
            let nsValue: NSString = value
            for var i = 1 ; i < result.numberOfRanges ; ++i {
                if let group = nsValue.substringWithRange(result.rangeAtIndex(i)).stringByRemovingPercentEncoding {
                    capturedGroups.append(group)
                }
            }
        }
        return capturedGroups
    }
    
    class func asciiRange(value: String) -> NSRange {
        return NSMakeRange(0, value.lengthOfBytesUsingEncoding(NSASCIIStringEncoding))
    }
    
    class func writeResponse(socket: CInt, response: HttpResponse, keepAlive: Bool) {
        Socket.writeStringUTF8(socket, string: "HTTP/1.1 \(response.statusCode()) \(response.reasonPhrase())\r\n")
        if let body = response.body() {
            Socket.writeStringASCII(socket, string: "Content-Length: \(body.length)\r\n")
        } else {
            Socket.writeStringASCII(socket, string: "Content-Length: 0\r\n")
        }
        if keepAlive {
            Socket.writeStringASCII(socket, string: "Connection: keep-alive\r\n")
        }
        for (name, value) in response.headers() {
            Socket.writeStringASCII(socket, string: "\(name): \(value)\r\n")
        }
        Socket.writeStringASCII(socket, string: "\r\n")
        if let body = response.body() {
            Socket.writeData(socket, data: body)
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


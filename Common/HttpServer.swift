//
//  HttpServer.swift
//
//  Created by Damian Kolakowski on 05/06/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

class HttpServer
{
    typealias Handler = HttpRequest -> HttpResponse
    
    var handlers: [(expression: NSRegularExpression, handler: Handler)] = []
    var acceptSocket: CInt = -1
    
    let matchingOptions = NSMatchingOptions(0)
    let expressionOptions = NSRegularExpressionOptions(0)
    
    subscript (path: String) -> Handler? {
        get {
            return nil
        }
        set ( newValue ) {
            if let regex: NSRegularExpression = NSRegularExpression(pattern: path, options: expressionOptions, error: nil) {
                if let newHandler = newValue {
                    handlers.append(expression: regex, handler: newHandler)
                }
            }
        }
    }
    
//    Uncommenting this will cause following compilation errors:
//
//      Cannot invoke 'subscript' with an argument list of type '($T5, Builtin.RawPointer)'
//      Cannot invoke 'subscript' with an argument list of type '($T5, Builtin.RawPointer)'
//
//    Swift stopped to support subscripts with multiple outputs.
//
//    subscript (asdasd: String) -> String {
//        get {
//            return asdasd
//        }
//        set ( directoryPath ) {
//            if let regex = NSRegularExpression(pattern: asdasd, options: expressionOptions, error: nil) {
//                handlers.append(expression: regex, handler: { request in
//                    let result = regex.firstMatchInString(request.url, options: self.matchingOptions, range: NSMakeRange(0, request.url.lengthOfBytesUsingEncoding(NSASCIIStringEncoding)))
//                    let nsPath: NSString = request.url
//                    let filesPath = directoryPath.stringByExpandingTildeInPath.stringByAppendingPathComponent(nsPath.substringWithRange(result!.rangeAtIndex(1)))
//                    if let fileBody = String(contentsOfFile: filesPath, encoding: NSUTF8StringEncoding, error: nil) {
//                        return HttpResponse.OK(.RAW(fileBody))
//                    }
//                    return HttpResponse.NotFound
//                })
//            }
//        }
//    }
    
    func routes() -> Array<String> {
        var results = [String]()
        for (expression,_) in handlers { results.append(expression.pattern) }
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
                        while let request = parser.nextHttpRequest(socket) {
                            let keepAlive = parser.supportsKeepAlive(request.headers)
                            if let (expression, handler) = self.findHandler(request.url) {
                                let capturedUrlsGroups = self.captureGroups(expression, value: request.url)
                                let updatedRequest = HttpRequest(url: request.url, method: request.method, headers: request.headers, body: request.body, capturedUrlGroups: capturedUrlsGroups)
                                HttpServer.writeResponse(socket, response: handler(updatedRequest), keepAlive: keepAlive)
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
    
    func findHandler(url:String) -> (NSRegularExpression, Handler)? {
        return filter(self.handlers, { (expression: NSRegularExpression, handler) -> Bool in
            return expression.numberOfMatchesInString(url, options: self.matchingOptions, range: NSMakeRange(0, url.lengthOfBytesUsingEncoding(NSASCIIStringEncoding))) > 0
        }).first
    }
    
    func captureGroups(expression: NSRegularExpression, value: String) -> [String] {
        var capturedGroups = [String]()
        if let result = expression.firstMatchInString(value, options: matchingOptions, range: NSMakeRange(0, value.lengthOfBytesUsingEncoding(NSASCIIStringEncoding))) {
            let nsValue: NSString = value
            for var i = 1 ; i < result.numberOfRanges ; ++i {
                capturedGroups.append(nsValue.substringWithRange(result.rangeAtIndex(i)))
            }
        }
        return capturedGroups
    }
    
    class func writeResponse(socket: CInt, response: HttpResponse, keepAlive: Bool) {
        Socket.writeStringUTF8(socket, string: "HTTP/1.1 \(response.statusCode()) \(response.reasonPhrase())\r\n")
        let messageBody = response.body()
        if let body = messageBody {
            if let nsdata = body.dataUsingEncoding(NSUTF8StringEncoding) {
                Socket.writeStringUTF8(socket, string: "Content-Length: \(nsdata.length)\r\n")
            }
        } else {
            Socket.writeStringUTF8(socket, string: "Content-Length: 0\r\n")
        }
        if keepAlive {
            Socket.writeStringUTF8(socket, string: "Connection: keep-alive\r\n")
        }
        //Socket.writeStringUTF8(socket, string: "Content-Type: text/html; charset=UTF-8\r\n")
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


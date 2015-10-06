//
//  HttpServer.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpServer
{
    static let VERSION = "1.0.2";
    
    public typealias Handler = HttpRequest -> HttpResponse
    
    var handlers: [(expression: NSRegularExpression, handler: Handler)] = []
    var clientSockets: Set<CInt> = []
    let clientSocketsLock = 0
    var acceptSocket: CInt = -1
    
    let matchingOptions = NSMatchingOptions(rawValue: 0)
    let expressionOptions = NSRegularExpressionOptions(rawValue: 0)
    
    public init() { }
    
    public subscript (path: String) -> Handler? {
        get {
            return nil
        }
        set ( newValue ) {
            do {
                let regex = try NSRegularExpression(pattern: path, options: expressionOptions)
                if let newHandler = newValue {
                    handlers.append(expression: regex, handler: newHandler)
                }
            } catch {
                    
            }
        }
    }
    
    public func routes() -> [String] { return handlers.map { $0.0.pattern } }
    
    public func start(listenPort: in_port_t = 8080, error: NSErrorPointer = nil) -> Bool {
        stop()
        if let socket = Socket.tcpForListen(listenPort, error: error) {
            self.acceptSocket = socket
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                while let socket = Socket.acceptClientSocket(self.acceptSocket) {
                    HttpServer.lock(self.clientSocketsLock) {
                        self.clientSockets.insert(socket)
                    }
                    if self.acceptSocket == -1 { return }
                    let socketAddress = Socket.peername(socket)
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
                        let parser = HttpParser()
                        while let request = parser.nextHttpRequest(socket) {
                            let keepAlive = parser.supportsKeepAlive(request.headers)
                            if let (expression, handler) = self.findHandler(request.url) {
                                let capturedUrlsGroups = self.captureExpressionGroups(expression, value: request.url)
                                let updatedRequest = HttpRequest(url: request.url, urlParams: request.urlParams, method: request.method, headers: request.headers, body: request.body, capturedUrlGroups: capturedUrlsGroups, address: socketAddress)
                                HttpServer.respond(socket, response: handler(updatedRequest), keepAlive: keepAlive)
                            } else {
                                HttpServer.respond(socket, response: HttpResponse.NotFound, keepAlive: keepAlive)
                            }
                            if !keepAlive { break }
                        }
                        Socket.release(socket)
                        HttpServer.lock(self.clientSocketsLock) {
                            self.clientSockets.remove(socket)
                        }
                    })
                }
                self.stop()
            })
            return true
        }
        return false
    }
    
    func findHandler(url:String) -> (NSRegularExpression, Handler)? {
		let u = NSURL(string: url)!
		let path = u.path!
		for handler in self.handlers {
			let regex = handler.0
            let matches = regex.numberOfMatchesInString(path, options: self.matchingOptions, range: HttpServer.asciiRange(path)) > 0
			if matches {
				return handler;
			}
        }
		return nil
    }
    
    func captureExpressionGroups(expression: NSRegularExpression, value: String) -> [String] {
		let u = NSURL(string: value)!
		let path = u.path!
        var capturedGroups = [String]()
        if let result = expression.firstMatchInString(path, options: matchingOptions, range: HttpServer.asciiRange(path)) {
            let nsValue: NSString = path
            for var i = 1 ; i < result.numberOfRanges ; ++i {
                if let group = nsValue.substringWithRange(result.rangeAtIndex(i)).stringByRemovingPercentEncoding {
                    capturedGroups.append(group)
                }
            }
        }
        return capturedGroups
    }
    
    public func stop() {
        Socket.release(acceptSocket)
        acceptSocket = -1
        HttpServer.lock(self.clientSocketsLock) {
            for clientSocket in self.clientSockets {
                Socket.release(clientSocket)
            }
            self.clientSockets.removeAll(keepCapacity: true)
        }
    }
    
    public class func asciiRange(value: String) -> NSRange {
        return NSMakeRange(0, value.lengthOfBytesUsingEncoding(NSASCIIStringEncoding))
    }
    
    public class func lock(handle: AnyObject, closure: () -> ()) {
        objc_sync_enter(handle)
        closure()
        objc_sync_exit(handle)
    }
    
    public class func respond(socket: CInt, response: HttpResponse, keepAlive: Bool) {
        Socket.writeUTF8(socket, string: "HTTP/1.1 \(response.statusCode()) \(response.reasonPhrase())\r\n")
        if let body = response.body() {
            Socket.writeASCII(socket, string: "Content-Length: \(body.length)\r\n")
        } else {
            Socket.writeASCII(socket, string: "Content-Length: 0\r\n")
        }
        if keepAlive {
            Socket.writeASCII(socket, string: "Connection: keep-alive\r\n")
        }
        for (name, value) in response.headers() {
            Socket.writeASCII(socket, string: "\(name): \(value)\r\n")
        }
        Socket.writeASCII(socket, string: "\r\n")
        if let body = response.body() {
            Socket.writeData(socket, data: body)
        }
    }
}


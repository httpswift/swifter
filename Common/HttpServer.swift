//
//  HttpServer.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpServer
{
    static let VERSION = "1.0.2";
    
    public typealias Handler = HttpRequest -> HttpResponse
    
    private var handlers: [(expression: NSRegularExpression, handler: Handler)] = []
    private var listenSocket: Socket = Socket(socketFileDescriptor: -1)
    private var clientSockets: Set<Socket> = []
    private let clientSocketsLock = 0
    
    public init() { }
    
    public subscript (path: String) -> Handler? {
        set {
            do {
                let regex = try NSRegularExpression(pattern: path, options: self.expressionOptions)
                if let newHandler = newValue {
                    self.handlers.append(expression: regex, handler: newHandler)
                    // Longer patterns will have higher priority.
                    self.handlers = self.handlers.sort { $0.0.pattern > $1.0.pattern }
                }
            } catch  {
                print("Could not register handler for: \(path), error: \(error)")
            }
        }
        get { return nil }
    }
    
    public var routes:[String] {
        return self.handlers.map { $0.expression.pattern }
    }
    
    public func start(listenPort: in_port_t = 8080) throws {
        self.stop()
        self.listenSocket = try Socket.tcpSocketForListen(listenPort)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            while let socket = try? self.listenSocket.acceptClientSocket() {
                HttpServer.lock(self.clientSocketsLock) {
                    self.clientSockets.insert(socket)
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                    let socketAddress = try? socket.peername()
                    let httpParser = HttpParser()
                    while let request = try? httpParser.readHttpRequest(socket) {
                        let keepAlive = httpParser.supportsKeepAlive(request.headers)
                        let response: HttpResponse
                        if let (expression, handler) = self.findHandler(request.url) {
                            let capturedUrlsGroups = self.captureExpressionGroups(expression, value: request.url)
                            let updatedRequest = HttpRequest(url: request.url, urlParams: request.urlParams, method: request.method, headers: request.headers, body: request.body, capturedUrlGroups: capturedUrlsGroups, address: socketAddress)
                            response = handler(updatedRequest)
                        } else {
                            response = HttpResponse.NotFound
                        }
                        do {
                            try HttpServer.respond(socket, response: response, keepAlive: keepAlive)
                        } catch {
                            print("Failed to send response: \(error)")
                            break
                        }
                        if !keepAlive { break }
                    }
                    socket.release()
                    HttpServer.lock(self.clientSocketsLock) {
                        self.clientSockets.remove(socket)
                    }
                }
            }
            self.stop()
        }
    }

    public func stop() {
        self.listenSocket.release()
        HttpServer.lock(self.clientSocketsLock) {
            for socket in self.clientSockets {
                socket.shutdown()
            }
            self.clientSockets.removeAll(keepCapacity: true)
        }
    }
    
    private let matchingOptions = NSMatchingOptions(rawValue: 0)
    private let expressionOptions = NSRegularExpressionOptions(rawValue: 0)
    
    private func findHandler(url:String) -> (NSRegularExpression, Handler)? {
        if let u = NSURL(string: url), path = u.path {
            for handler in self.handlers {
                if handler.expression.numberOfMatchesInString(path, options: self.matchingOptions, range: HttpServer.asciiRange(path)) > 0 {
                    return handler
                }
            }
        }
        return nil
    }
    
    private func captureExpressionGroups(expression: NSRegularExpression, value: String) -> [String] {
        guard let u = NSURL(string: value), path = u.path else {
            return []
        }
        var capturedGroups = [String]()
        if let result = expression.firstMatchInString(path, options: matchingOptions, range: HttpServer.asciiRange(path)) {
            let nsValue: NSString = path
            for i in 1..<result.numberOfRanges {
                if let group = nsValue.substringWithRange(result.rangeAtIndex(i)).stringByRemovingPercentEncoding {
                    capturedGroups.append(group)
                }
            }
        }
        return capturedGroups
    }
    
    private class func asciiRange(value: String) -> NSRange {
        return NSMakeRange(0, value.lengthOfBytesUsingEncoding(NSASCIIStringEncoding))
    }
    
    private class func lock(handle: AnyObject, closure: () -> ()) {
        objc_sync_enter(handle)
        closure()
        objc_sync_exit(handle)
    }
    
    private class func respond(socket: Socket, response: HttpResponse, keepAlive: Bool) throws {
        try socket.writeASCII("HTTP/1.1 \(response.statusCode()) \(response.reasonPhrase())\r\n")
        
        let length = response.body()?.length ?? 0
        try socket.writeASCII("Content-Length: \(length)\r\n")
        
        if keepAlive {
            try socket.writeASCII("Connection: keep-alive\r\n")
        }
        for (name, value) in response.headers() {
            try socket.writeASCII("\(name): \(value)\r\n")
        }
        try socket.writeASCII("\r\n")
        if let body = response.body() {
            try socket.writeData(body)
        }
    }
}


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
    
    private(set) var handlers: [(expression: NSRegularExpression, handler: Handler)] = []
    private(set) var acceptSocket: CInt = -1
    private(set) var clientSockets: Set<CInt> = []
    private let clientSocketsLock = 0

    
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
            } catch  {
                print("Could not register handler for: \(path), error: \(error)")
            }
        }
    }
    
    public var routes:[String] {
        return self.handlers.map { $0.0.pattern }
    }
    
    public func start(listenPort: in_port_t = 8080) throws {
        self.stop()
        self.acceptSocket = try Socket.tcpForListen(listenPort)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            while let socket = try? Socket.acceptClientSocket(self.acceptSocket) {
                HttpServer.lock(self.clientSocketsLock) {
                    self.clientSockets.insert(socket)
                }
                if self.acceptSocket == -1 { return }
                let socketAddress = try? Socket.peername(socket)!
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                    let parser = HttpParser()
                    while let request = try? parser.nextHttpRequest(socket) {
                        let keepAlive = parser.supportsKeepAlive(request.headers)
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
                    Socket.release(socket)
                    HttpServer.lock(self.clientSocketsLock) {
                        self.clientSockets.remove(socket)
                    }
                }
            }
            self.stop()
        }
    }
    
    func findHandler(url:String) -> (NSRegularExpression, Handler)? {
        if let u = NSURL(string: url), path = u.path {
            for handler in self.handlers {
                if handler.expression.numberOfMatchesInString(path, options: self.matchingOptions, range: HttpServer.asciiRange(path)) > 0 {
                    return handler
                }
            }
        }
		return nil
    }
    
    func captureExpressionGroups(expression: NSRegularExpression, value: String) -> [String] {
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
    
    public func stop() {
        Socket.release(acceptSocket)
        self.acceptSocket = -1
        HttpServer.lock(self.clientSocketsLock) {
            for clientSocket in self.clientSockets {
                Socket.release(clientSocket)
            }
            self.clientSockets.removeAll(keepCapacity: true)
        }
    }
    
    private class func asciiRange(value: String) -> NSRange {
        return NSMakeRange(0, value.lengthOfBytesUsingEncoding(NSASCIIStringEncoding))
    }
    
    private class func lock(handle: AnyObject, closure: () -> ()) {
        objc_sync_enter(handle)
        closure()
        objc_sync_exit(handle)
    }
    
    private class func respond(socket: CInt, response: HttpResponse, keepAlive: Bool) throws {
        try Socket.writeUTF8(socket, string: "HTTP/1.1 \(response.statusCode()) \(response.reasonPhrase())\r\n")
        
        let length = response.body()?.length ?? 0
        try Socket.writeASCII(socket, string: "Content-Length: \(length)\r\n")
        
        if keepAlive {
            try Socket.writeASCII(socket, string: "Connection: keep-alive\r\n")
        }
        for (name, value) in response.headers() {
            try Socket.writeASCII(socket, string: "\(name): \(value)\r\n")
        }
        try Socket.writeASCII(socket, string: "\r\n")
        if let body = response.body() {
            try Socket.writeData(socket, data: body)
        }
    }
}


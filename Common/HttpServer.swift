//
//  HttpServer.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpServer
{
    static let VERSION = "1.0.2";
    
    typealias HandlerLine = (rawExpression: String, expression: NSRegularExpression, handler: Handler)
    
    public typealias Handler = HttpRequest -> HttpResponse
    
    private(set) var handlers: [HandlerLine] = []
    private(set) var acceptSocket: Socket!
    private(set) var clientSockets: Set<Socket> = []
    private let clientSocketsLock = 0

    
    let matchingOptions = NSMatchingOptions(rawValue: 0)
    let expressionOptions = NSRegularExpressionOptions(rawValue: 0)
    
    public init() { }
    
    public subscript (path: String) -> Handler? {
        get {
            return nil
        }
        
        set {
            do {
                let regex = try NSRegularExpression(pattern: path, options: self.expressionOptions)
                if let newHandler = newValue {
                    self.handlers.append(rawExpression: path, expression: regex, handler: newHandler)
                }
            } catch  {
                print("Could not register handler for: \(path), error: \(error)")
            }
        }
    }
    
    public var routes:[String] {
        return self.handlers.map { $0.expression.pattern }
    }
    
    public func start(listenPort: in_port_t = 8080) throws {
        self.stop()
        self.acceptSocket = try Socket(port:listenPort)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            while let socket = try? self.acceptSocket.acceptClientSocket() {
                HttpServer.lock(self.clientSocketsLock) {
                    self.clientSockets.insert(socket)
                }
                let socketAddress = try? self.acceptSocket.peername()
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
                    let parser = HttpParser()
                    while let request = try? parser.nextHttpRequest(socket) {
                        let keepAlive = parser.supportsKeepAlive(request.headers)
                        let response: HttpResponse
                        if let (_, expression, handler) = self.findHandler(request.url) {
                            let capturedUrlsGroups = self.captureExpressionGroups(expression, value: request.url)
                            let updatedRequest = HttpRequest(url: request.url, urlParams: request.urlParams, method: request.method, headers: request.headers, body: request.body, capturedUrlGroups: capturedUrlsGroups, address: socketAddress)
                            response = handler(updatedRequest)
                        } else {
                            print("handler not found")
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
                    HttpServer.lock(self.clientSocketsLock) {
                        self.clientSockets.remove(socket)
                    }
                }
            }
            self.stop()
        }
    }
    
    func findHandler(url:String) -> HandlerLine? {
        if let u = NSURL(string: url), path = u.path {
            var res = self.handlers.filter { $0.expression.numberOfMatchesInString(path, options: self.matchingOptions, range: HttpServer.asciiRange(path)) > 0 }
            
            if res.count > 1 {
                // we eliminate first the "/" route
                res = res.filter { $0.rawExpression != "/" }
                
                // if there is still the conflict, we take the better matching route
                if res.count > 1 {
                    print("conflict between routes")
                    let weight = res.map { $0.expression.numberOfMatchesInString(path, options: self.matchingOptions, range: HttpServer.asciiRange(path)) }
                    res = [res[weight.indexOf(weight.maxElement()!)!]]

                }
            }
            
            if res.count > 0 {
                return res[0]
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
//        self.acceptSocket?.release()
        self.acceptSocket = nil
        HttpServer.lock(self.clientSocketsLock) {
//            for clientSocket in self.clientSockets {
//                clientSocket.release()
//            }
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
    
    private class func respond(socket: Socket, response: HttpResponse, keepAlive: Bool) throws {
        try socket.writeUTF8("HTTP/1.1 \(response.statusCode()) \(response.reasonPhrase())\r\n")
        
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


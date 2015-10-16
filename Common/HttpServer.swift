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
    
    private(set) var handlers: [(expression: NSRegularExpression, handler: Handler)] = []
    private(set) var clientSockets: Set<CInt> = []
    let clientSocketsLock = 0
    private(set) var acceptSocket: CInt = -1
    
    let matchingOptions = NSMatchingOptions(rawValue: 0)
    let expressionOptions = NSRegularExpressionOptions(rawValue: 0)
    
    public init() { }
    
    public subscript (path: String) -> Handler? {
        get {
            return nil
        }
        
        set {
            if let newHandler = newValue,
               let regex = try? NSRegularExpression(pattern: path, options: expressionOptions){
                self.handlers.append(expression: regex, handler: newHandler)
            }
        }
    }
    
    public var routes:[String] {
        return self.handlers.map { $0.0.pattern }
    }
    
    public func start(listenPort: in_port_t = 8080) throws {
        self.stop()
        do {
            let socket = try Socket.tcpForListen(listenPort)
            self.acceptSocket = socket
            
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
                            HttpServer.respond(socket, response: response, keepAlive: keepAlive)

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
        } catch {
            throw error
        }
    }
    
    func findHandler(url:String) -> (NSRegularExpression, Handler)? {
        if let u = NSURL(string: url),
                  path = u.path {
            for handler in self.handlers {
                if handler.expression.numberOfMatchesInString(path, options: self.matchingOptions, range: HttpServer.asciiRange(path)) > 0 {
                    return handler;
                }
            }
        }
		return nil
    }
    
    func captureExpressionGroups(expression: NSRegularExpression, value: String) -> [String] {
        var capturedGroups = [String]()
        
        guard let u = NSURL(string: value),
                  path = u.path else {
                return capturedGroups
        }
        
        if let result = expression.firstMatchInString(path, options: matchingOptions, range: HttpServer.asciiRange(path)) {
            let nsValue: NSString = path
            for i in 1..<result.numberOfRanges {
                if let group = nsValue.substringWithRange(result.rangeAtIndex(i)).stringByRemovingPercentEncoding {
                    capturedGroups.append(group)
                }
            }
//            for var i = 1 ; i < result.numberOfRanges ; ++i {
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
    
    public class func asciiRange(value: String) -> NSRange {
        return NSMakeRange(0, value.lengthOfBytesUsingEncoding(NSASCIIStringEncoding))
    }
    
    public class func lock(handle: AnyObject, closure: () -> ()) {
        objc_sync_enter(handle)
        closure()
        objc_sync_exit(handle)
    }
    
    public class func respond(socket: CInt, response: HttpResponse, keepAlive: Bool) {
        do {
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
        } catch {
            // TODO: handle error
            print("error responding to client")
        }
        
    }
}


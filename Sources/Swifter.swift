//
//  HttpServer.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public class Swifter {
    
    public static let version = "2.0.0a"
    
    private let router: Router<(([String: String], Request, @escaping ((Response) -> Void)) -> Void)>
    private let server: Server
    
    public var notFoundHandler: ((Request) -> Response)?
    
    public var middleware = Array<((Request) -> Response?)>()
    
    public init(_ port: in_port_t = 8080) throws {
        self.router = Router()
        self.server = try Server(port)
    }
    
    public func get(_ path: String, _ closure: @escaping (([String: String], Request, @escaping ((Response) -> Void)) -> Void)) {
        router.attach("GET", path: path, handler: closure)
    }
    
    public func post(_ path: String, _ closure: @escaping (([String: String], Request, @escaping ((Response) -> Void)) -> Void)) {
        router.attach("POST", path: path, handler: closure)
    }
    
    public func put(_ path: String, _ closure: @escaping (([String: String], Request, @escaping ((Response) -> Void)) -> Void)) {
        router.attach("PUT", path: path, handler: closure)
    }
    
    public func delete(_ path: String, _ closure: @escaping (([String: String], Request, @escaping ((Response) -> Void)) -> Void)) {
        router.attach("DELETE", path: path, handler: closure)
    }
    
    public func options(_ path: String, _ closure: @escaping (([String: String], Request, @escaping ((Response) -> Void)) -> Void)) {
        router.attach("OPTIONS", path: path, handler: closure)
    }
    
    public subscript(path: String) -> (([String: String], Request, @escaping ((Response) -> Void)) -> Void)? {
        set {
            router.attach(nil, path: path, handler: newValue)
        }
        get { return nil }
    }
    
    public var routes: [String] {
        return router.routes();
    }
    
    public func loop() throws {
        try self.server.serve { request, responder in
            var middlewareResponse: Response? = nil
            for layer in self.middleware {
                if let responseFound = layer(request) {
                    middlewareResponse = responseFound
                    break
                }
            }
            if let middlewareResponseFound = middlewareResponse {
                responder(middlewareResponseFound)
            } else {
                if let (params, response) = self.router.route(request.method, path: request.path) {
                    response(params, request, responder)
                } else {
                    if let notFoundHandler = self.notFoundHandler {
                        responder(notFoundHandler(request))
                    } else {
                        responder(Response(404))
                    }
                }
            }
        }
    }
}

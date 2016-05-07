//
//  HttpServer2.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpServer: HttpServerIO {
    
    public static let VERSION = "1.1.3"
    
    private let router = HttpRouter()
    
    public override init() {
        self.DELETE = MethodRoute(method: "DELETE", router: router)
        self.UPDATE = MethodRoute(method: "UPDATE", router: router)
        self.HEAD   = MethodRoute(method: "HEAD", router: router)
        self.POST   = MethodRoute(method: "POST", router: router)
        self.GET    = MethodRoute(method: "GET", router: router)
        self.PUT    = MethodRoute(method: "PUT", router: router)
    }
    
    public var DELETE, UPDATE, HEAD, POST, GET, PUT : MethodRoute
    
    public func get(_ path: String, _ handler: (HttpRequest -> HttpResponse)) {
        router.register("GET", path: path, handler: handler)
    }
    
    public func post(_ path: String, _ handler: (HttpRequest -> HttpResponse)) {
        router.register("POST", path: path, handler: handler)
    }
    
    public func put(_ path: String, _ handler: (HttpRequest -> HttpResponse)) {
        router.register("PUT", path: path, handler: handler)
    }
    
    public func head(_ path: String, _ handler: (HttpRequest -> HttpResponse)) {
        router.register("HEAD", path: path, handler: handler)
    }
    
    public func delete(_ path: String, _ handler: (HttpRequest -> HttpResponse)) {
        router.register("DELETE", path: path, handler: handler)
    }
    
    public func update(_ path: String, _ handler: (HttpRequest -> HttpResponse)) {
        router.register("UPDATE", path: path, handler: handler)
    }

    public subscript(path: String) -> (HttpRequest -> HttpResponse)? {
        set {
            router.register(nil, path: path, handler: newValue)
        }
        get { return nil }
    }
    
    public var routes: [String] {
        return router.routes();
    }
    
    public var notFoundHandler: (HttpRequest -> HttpResponse)?

    override public func dispatch(_ method: String, path: String) -> ([String:String], HttpRequest -> HttpResponse) {
        if let result = router.route(method, path: path) {
            return result
        }
        if let notFoundHandler = self.notFoundHandler {
            return ([:], notFoundHandler)
        }
        return super.dispatch(method, path: path)
    }
    
    public struct MethodRoute {
        public let method: String
        public let router: HttpRouter
        public subscript(path: String) -> (HttpRequest -> HttpResponse)? {
            set {
                router.register(method, path: path, handler: newValue)
            }
            get { return nil }
        }
    }
}
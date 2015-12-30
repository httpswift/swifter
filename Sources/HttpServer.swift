//
//  HttpServer2.swift
//  Swifter
//
//  Created by Damian Kolakowski on 17/12/15.
//  Copyright © 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpServer: HttpServerIO {
    
    public static let VERSION = "1.0.6"
    
    private let router = HttpRouter()
    
    public override init() {
        self.DELETE = Route(method: "DELETE", router: self.router)
        self.UPDATE = Route(method: "UPDATE", router: self.router)
        self.HEAD   = Route(method: "HEAD", router: self.router)
        self.POST   = Route(method: "POST", router: self.router)
        self.GET    = Route(method: "GET", router: self.router)
        self.PUT    = Route(method: "PUT", router: self.router)
    }
    
    public var DELETE, UPDATE, HEAD, POST, GET, PUT : Route;
    
    public var routes: [(method: String?, path: String)] {
        return router.routes();
    }
    
    public subscript(path: String) -> (HttpRequest -> HttpResponse)? {
        set {
            if let handler = newValue {
                self.router.register(nil, path: path, handler: handler)
            } else {
                self.router.unregister(nil, path: path)
            }
        }
        get { return nil }
    }
    
    public struct Route {
        public let method: String
        public let router: HttpRouter
        public subscript(path: String) -> (HttpRequest -> HttpResponse)? {
            set {
                if let handler = newValue {
                    router.register(method, path: path, handler: handler)
                } else {
                    router.unregister(method, path: path)
                }
            }
            get { return nil }
        }
    }

    override public func dispatch(method: String, url: String) -> ([String:String], HttpRequest -> HttpResponse) {
        if let handler = router.select(method, url: url) {
            return handler
        }
        return super.dispatch(method, url: url)
    }
}
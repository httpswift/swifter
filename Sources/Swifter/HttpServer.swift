//
//  HttpServer2.swift
//  Swifter
//
//  Created by Damian Kolakowski on 17/12/15.
//  Copyright © 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpServer: HttpServerIO {
    
    private let router = HttpRouter()
    
    public var routes: [(method: String?, path: String)] {
        return router.routes()
    }
    
    public subscript(path: String) -> (HttpRequest -> HttpResponse)? {
        set {
            if let handler = newValue {
                self.router.register(nil, path: path, handler: handler)
            }
            else {
                self.router.unregister(nil, path: path)
            }
        }
        get { return nil }
    }
    
    public lazy var DELETE : Route = self.lazyBuild("DELETE")
    public lazy var UPDATE : Route = self.lazyBuild("UPDATE")
    public lazy var HEAD   : Route = self.lazyBuild("HEAD")
    public lazy var POST   : Route = self.lazyBuild("POST")
    public lazy var GET    : Route = self.lazyBuild("GET")
    public lazy var PUT    : Route = self.lazyBuild("PUT")
    
    public struct Route {
        public let method: String
        public let server: HttpServer
        public subscript(path: String) -> (HttpRequest -> HttpResponse)? {
            set {
                if let handler = newValue {
                    server.router.register(method, path: path, handler: handler)
                } else {
                    server.router.unregister(method, path: path)
                }
            }
            get { return nil }
        }
    }
    
    private func lazyBuild(method: String) -> Route {
        return Route(method: method, server: self)
    }
    
    override public func select(method: String, url: String) -> ([String : String], HttpRequest -> HttpResponse) {
        if let handler = router.select(method, url: url) {
            return handler
        }
        return super.select(method, url: url)
    }
}
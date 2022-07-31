//
//  HttpServer.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

open class HttpServer: HttpServerIO {

    public static let VERSION: String = {

        #if os(Linux)
        return "1.5.0"
        #else
        let bundle = Bundle(for: HttpServer.self)
        guard let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String else { return "Unspecified" }
        return version
        #endif
    }()

    private let router = HttpRouter()

    public override init() {
        self.DELETE = MethodRoute(method: "DELETE", router: router)
        self.PATCH  = MethodRoute(method: "PATCH", router: router)
        self.HEAD   = MethodRoute(method: "HEAD", router: router)
        self.POST   = MethodRoute(method: "POST", router: router)
        self.GET    = MethodRoute(method: "GET", router: router)
        self.PUT    = MethodRoute(method: "PUT", router: router)

        self.delete = MethodRoute(method: "DELETE", router: router)
        self.patch  = MethodRoute(method: "PATCH", router: router)
        self.head   = MethodRoute(method: "HEAD", router: router)
        self.post   = MethodRoute(method: "POST", router: router)
        self.get    = MethodRoute(method: "GET", router: router)
        self.put    = MethodRoute(method: "PUT", router: router)
    }

    public var DELETE, PATCH, HEAD, POST, GET, PUT: MethodRoute
    public var delete, patch, head, post, get, put: MethodRoute

    public subscript(path: String) -> ((HttpRequest) async -> HttpResponse)? {
        get { return nil }
        set {
            router.register(nil, path: path, handler: newValue)
        }
    }

    public var routes: [String] {
        return router.routes()
    }

    public var notFoundHandler: ((HttpRequest) -> HttpResponse)?

    public var middleware = [(HttpRequest) -> HttpResponse?]()

    override open func dispatch(_ request: HttpRequest) -> ([String: String], (HttpRequest) async -> HttpResponse) {
        for layer in middleware {
            if let response = layer(request) {
                return ([:], { _ in response })
            }
        }
        if let result = router.route(request.method, path: request.path) {
            return result
        }
        if let notFoundHandler = self.notFoundHandler {
            return ([:], notFoundHandler)
        }
        return super.dispatch(request)
    }

    public struct MethodRoute {
        public let method: String
        public let router: HttpRouter
        public subscript(paths: String...) -> ((HttpRequest) async -> HttpResponse)? {
            get { return nil }
            set {
                paths.forEach { router.register(method, path: $0, handler: newValue) }
            }
        }
        public subscript<T: Controller>(paths: String...) -> ((T) -> () async -> HttpResponse)? {
            get { nil }
            set {
                guard let newValue = newValue else { return }
                paths.forEach { path in
                    router.register(method, path: path) { request in
                        await newValue(T(request: request))()
                    }
                }
            }
        }
    }
}

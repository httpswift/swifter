//
//  HttpServer.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

open class HttpServer: HttpServerIO {
    public init() {
        self.post = MethodRoute(method: "POST", router: router)
        self.get  = MethodRoute(method: "GET",  router: router)
    }
    public static let version = Bundle(for: HttpServer.self).infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.5.1"
    
    private let router = HttpRouter()
    public var post, get: MethodRoute
    
    public subscript(path: String) -> httpReq? {
        get { return nil }
        set { router.register(nil, path: path, handler: newValue) }
    }
    
    public var routes: [String] {
        router.routes()
    }
        
    override open func dispatch(_ request: HttpRequest) -> dispatchHttpReq {
        guard
            let result = router.route(request.method, path: request.path)
        else {
            return ([:], { _ in HttpResponse.notFound(nil) })
        }
            
        return result
    }
}

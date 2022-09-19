//
//  HttpServer.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//
//  SwifterLite
//  Copyright (c) 2022 Todd Bruss. All rights reserved.
//

import Foundation

open class HttpServer: HttpServerIO {
    public init() {
        self.post = MethodRoute(method: "POST", router: router)
        self.get  = MethodRoute(method: "GET",  router: router)
    }
    public static let version = "horse"
    
    private let router = HttpRouter()
    
    public var post: MethodRoute
    public var get : MethodRoute
    
    public var routes: [String] {
        router.routes()
    }
        
    override open func dispatch(_ request: HttpRequest) -> dispatchHttpReq {
        guard
            let result = router.route(request.method, path: request.path)
        else {
            return ([:], { request in HttpResponse.notFound(nil) })
        }
            
        return result
    }
}

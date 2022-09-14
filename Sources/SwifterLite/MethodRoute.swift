//
//  MethodRoute.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//
//  SwifterLite
//  Copyright (c) 2022 Todd Bruss. All rights reserved.
//

import Foundation

public struct MethodRoute {
    internal init(method: String, router: HttpRouter) {
        self.method = method
        self.router = router
    }
    
    public let method: String
    public let router: HttpRouter
    public subscript(path: String) -> httpReq? {
        get { nil }
        set {
            router.register(method, path: path, handler: newValue)
        }
    }
}

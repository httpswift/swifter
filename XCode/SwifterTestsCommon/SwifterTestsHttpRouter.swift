//
//  SwifterTestsHttpRouter.swift
//  Swifter
//

//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest
import Swifter

class SwifterTestsHttpRouter: XCTestCase {

    func testHttpRouterSlashRoot() {
        
        let router = HttpRouter()
        
        router.register(nil, path: "/", handler: { r in
            return .ok(.html("OK"))
        })
        
        XCTAssert(router.route(nil, path: "/") != nil)
    }
    
    func testHttpRouterSimplePathSegments() {
        
        let router = HttpRouter()
        
        router.register(nil, path: "/a/b/c/d", handler: { r in
            return .ok(.html("OK"))
        })
        
        XCTAssert(router.route(nil, path: "/") == nil)
        XCTAssert(router.route(nil, path: "/a") == nil)
        XCTAssert(router.route(nil, path: "/a/b") == nil)
        XCTAssert(router.route(nil, path: "/a/b/c") == nil)
        XCTAssert(router.route(nil, path: "/a/b/c/d") != nil)
    }
    
    func testHttpRouterSinglePathSegmentWildcard() {
        
        let router = HttpRouter()
        
        router.register(nil, path: "/a/*/c/d", handler: { r in
            return .ok(.html("OK"))
        })
        
        XCTAssert(router.route(nil, path: "/") == nil)
        XCTAssert(router.route(nil, path: "/a") == nil)
        XCTAssert(router.route(nil, path: "/a/foo/c/d") != nil)
        XCTAssert(router.route(nil, path: "/a/b/c/d") != nil)
        XCTAssert(router.route(nil, path: "/a/b") == nil)
        XCTAssert(router.route(nil, path: "/a/b/foo/d") == nil)
    }
    
    func testHttpRouterVariables() {
        
        let router = HttpRouter()
        
        router.register(nil, path: "/a/:arg1/:arg2/b/c/d/:arg3", handler: { r in
            return .ok(.html("OK"))
        })
        
        XCTAssert(router.route(nil, path: "/") == nil)
        XCTAssert(router.route(nil, path: "/a") == nil)
        XCTAssert(router.route(nil, path: "/a/b/c/d") == nil)
        XCTAssert(router.route(nil, path: "/a/value1/value2/b/c/d/value3")?.0[":arg1"] == "value1")
        XCTAssert(router.route(nil, path: "/a/value1/value2/b/c/d/value3")?.0[":arg2"] == "value2")
        XCTAssert(router.route(nil, path: "/a/value1/value2/b/c/d/value3")?.0[":arg3"] == "value3")
    }
    
    func testHttpRouterMultiplePathSegmentWildcards() {
        
        let router = HttpRouter()
        
        router.register(nil, path: "/a/**/e/f/g", handler: { r in
            return .ok(.html("OK"))
        })
        
        XCTAssert(router.route(nil, path: "/") == nil)
        XCTAssert(router.route(nil, path: "/a") == nil)
        XCTAssert(router.route(nil, path: "/a/b/c/d/e/f/g") != nil)
        XCTAssert(router.route(nil, path: "/a/e/f/g") == nil)
    }
    
    func testHttpRouterEmptyTail() {
        
        let router = HttpRouter()
        
        router.register(nil, path: "/a/b/", handler: { r in
            return .ok(.html("OK"))
        })
        
        router.register(nil, path: "/a/b/:var", handler: { r in
            return .ok(.html("OK"))
        })

        
        XCTAssert(router.route(nil, path: "/") == nil)
        XCTAssert(router.route(nil, path: "/a") == nil)
        XCTAssert(router.route(nil, path: "/a/b/") != nil)
        XCTAssert(router.route(nil, path: "/a/e/f/g") == nil)
        
        XCTAssert(router.route(nil, path: "/a/b/value1")?.0[":var"] == "value1")
        
        XCTAssert(router.route(nil, path: "/a/b/")?.0[":var"] == "")
    }

}

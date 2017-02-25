//
//  SwifterTestsHttpRouter.swift
//  Swifter
//

//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest

class SwifterTestsHttpRouter: XCTestCase {
    
    func testHttpRouterSlashRoot() {
        
        let router = Router<String>()
        
        router.attach(nil, path: "/", handler: "")
        
        XCTAssertNotNil(router.route(nil, path: "/"))
    }
    
    func testHttpRouterSimplePathSegments() {
        
        let router = Router<String>()
        
        router.attach(nil, path: "/a/b/c/d", handler: "")
        
        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNil(router.route(nil, path: "/a/b"))
        XCTAssertNil(router.route(nil, path: "/a/b/c"))
        XCTAssertNotNil(router.route(nil, path: "/a/b/c/d"))
    }
    
    func testHttpRouterSinglePathSegmentWildcard() {
        
        let router = Router<String>()
        
        router.attach(nil, path: "/a/*/c/d", handler: "")
        
        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNotNil(router.route(nil, path: "/a/foo/c/d"))
        XCTAssertNotNil(router.route(nil, path: "/a/b/c/d"))
        XCTAssertNil(router.route(nil, path: "/a/b"))
        XCTAssertNil(router.route(nil, path: "/a/b/foo/d"))
    }
    
    func testHttpRouterVariables() {
        
        let router = Router<String>()
        
        router.attach(nil, path: "/a/:arg1/:arg2/b/c/d/:arg3", handler: "")
        
        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNil(router.route(nil, path: "/a/b/c/d"))
        XCTAssertEqual(router.route(nil, path: "/a/value1/value2/b/c/d/value3")?.0[":arg1"], "value1")
        XCTAssertEqual(router.route(nil, path: "/a/value1/value2/b/c/d/value3")?.0[":arg2"], "value2")
        XCTAssertEqual(router.route(nil, path: "/a/value1/value2/b/c/d/value3")?.0[":arg3"], "value3")
    }
    
    func testHttpRouterMultiplePathSegmentWildcards() {
        
        let router = Router<String>()
        
        router.attach(nil, path: "/a/**/e/f/g", handler: "")
        
        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNotNil(router.route(nil, path: "/a/b/c/d/e/f/g"))
        XCTAssertNil(router.route(nil, path: "/a/e/f/g"))
    }
    
    func testHttpRouterEmptyTail() {
        
        let router = Router<String>()
        
        router.attach(nil, path: "/a/b/", handler: "")
        
        router.attach(nil, path: "/a/b/:var", handler: "")
        
        
        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNotNil(router.route(nil, path: "/a/b/"))
        XCTAssertNil(router.route(nil, path: "/a/e/f/g"))
        
        XCTAssertEqual(router.route(nil, path: "/a/b/value1")?.0[":var"], "value1")
        
        XCTAssertEqual(router.route(nil, path: "/a/b/")?.0[":var"], "")
    }
    
}

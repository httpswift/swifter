//
//  SwifterTestsHttpRouter.swift
//  Swifter
//

//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest
@testable import Swifter

class SwifterTestsHttpRouter: XCTestCase {
    
    func testHttpRouterSlashRoot() {
        
        let router = HttpRouter()
        
        router.register(nil, path: "/", handler: { r in
            return .ok(.html("OK"))
        })
        
        XCTAssertNotNil(router.route(nil, path: "/"))
    }
    
    func testHttpRouterSimplePathSegments() {
        
        let router = HttpRouter()
        
        router.register(nil, path: "/a/b/c/d", handler: { r in
            return .ok(.html("OK"))
        })
        
        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNil(router.route(nil, path: "/a/b"))
        XCTAssertNil(router.route(nil, path: "/a/b/c"))
        XCTAssertNotNil(router.route(nil, path: "/a/b/c/d"))
    }
    
    func testHttpRouterSinglePathSegmentWildcard() {
        
        let router = HttpRouter()
        
        router.register(nil, path: "/a/*/c/d", handler: { r in
            return .ok(.html("OK"))
        })
        
        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNotNil(router.route(nil, path: "/a/foo/c/d"))
        XCTAssertNotNil(router.route(nil, path: "/a/b/c/d"))
        XCTAssertNil(router.route(nil, path: "/a/b"))
        XCTAssertNil(router.route(nil, path: "/a/b/foo/d"))
    }
    
    func testHttpRouterVariables() {
        
        let router = HttpRouter()
        
        router.register(nil, path: "/a/:arg1/:arg2/b/c/d/:arg3", handler: { r in
            return .ok(.html("OK"))
        })
        
        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNil(router.route(nil, path: "/a/b/c/d"))
        XCTAssertEqual(router.route(nil, path: "/a/value1/value2/b/c/d/value3")?.0[":arg1"], "value1")
        XCTAssertEqual(router.route(nil, path: "/a/value1/value2/b/c/d/value3")?.0[":arg2"], "value2")
        XCTAssertEqual(router.route(nil, path: "/a/value1/value2/b/c/d/value3")?.0[":arg3"], "value3")
    }
    
    func testHttpRouterMultiplePathSegmentWildcards() {
        
        let router = HttpRouter()
        
        router.register(nil, path: "/a/**/e/f/g", handler: { r in
            return .ok(.html("OK"))
        })
        
        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNotNil(router.route(nil, path: "/a/b/c/d/e/f/g"))
        XCTAssertNil(router.route(nil, path: "/a/e/f/g"))
    }
    
    func testHttpRouterEmptyTail() {
        
        let router = HttpRouter()
        
        router.register(nil, path: "/a/b/", handler: { r in
            return .ok(.html("OK"))
        })
        
        router.register(nil, path: "/a/b/:var", handler: { r in
            return .ok(.html("OK"))
        })
        
        
        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNotNil(router.route(nil, path: "/a/b/"))
        XCTAssertNil(router.route(nil, path: "/a/e/f/g"))
        
        XCTAssertEqual(router.route(nil, path: "/a/b/value1")?.0[":var"], "value1")
        
        XCTAssertEqual(router.route(nil, path: "/a/b/")?.0[":var"], "")
    }
    
    func testHttpRouterPercentEncodedPathSegments() {
        
        let router = HttpRouter()
        
        router.register(nil, path: "/a/<>/^", handler: { r in
            return .ok(.html("OK"))
        })
        XCTAssertNil(router.route(nil, path: "/"))
        XCTAssertNil(router.route(nil, path: "/a"))
        XCTAssertNotNil(router.route(nil, path: "/a/%3C%3E/%5E"))
    }
    
    func testHttpRouterHandlesOverlappingPaths() {
        
        let router = HttpRouter()
        let request = HttpRequest()
        
        let staticRouteExpectation = expectation(description: "Static Route")
        var foundStaticRoute = false
        router.register("GET", path: "a/b") { _ in
            foundStaticRoute = true
            staticRouteExpectation.fulfill()
            return HttpResponse.accepted
        }
        
        let variableRouteExpectation = expectation(description: "Variable Route")
        var foundVariableRoute = false
        router.register("GET", path: "a/:id/c") { _ in
            foundVariableRoute = true
            variableRouteExpectation.fulfill()
            return HttpResponse.accepted
        }
        
        let staticRouteResult = router.route("GET", path: "a/b")
        let staticRouterHandler = staticRouteResult?.1
        XCTAssertNotNil(staticRouteResult)
        _ = staticRouterHandler?(request)
        
        let variableRouteResult = router.route("GET", path: "a/b/c")
        let variableRouterHandler = variableRouteResult?.1
        XCTAssertNotNil(variableRouteResult)
        _ = variableRouterHandler?(request)
        
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertTrue(foundStaticRoute)
        XCTAssertTrue(foundVariableRoute)
    }
}

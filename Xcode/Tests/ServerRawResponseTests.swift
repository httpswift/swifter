//
//  ServerRawResponseTests.swift
//  Swifter
//
//  Created by Stuart Espey on 11/08/22.

import XCTest
#if os(Linux)
import FoundationNetworking
#endif
@testable import Swifter

class ServerRawResponseTests: XCTestCase {

    public enum TestError: Error {
        case aborted
    }

    var server: HttpServer!

    override func setUp() {
        super.setUp()
        server = HttpServer()
    }

    override func tearDown() {
        if server.operating {
            server.stop()
        }
        server = nil
        super.tearDown()
    }

    /**
        Adds the handler, at the teststring path, then expects that XXX-CustomHeader is equal to testString, and the
        body. Test should pass instantly-ish.

        If expectError is true, then an error is expected, and response and body should be nil
     */
    func doHandlerTest( handler: @escaping (HttpRequest) -> HttpResponse, testString: String, expectError: Bool = false) {
        let path = "/\(testString)"
        server.GET[path] = handler

        var requestExpectation: XCTestExpectation? = expectation(description: "Should handle the request quickly")

        do {
            try server.start()

            DispatchQueue.global().async {

                let task = URLSession.shared.executeAsyncTask(path: path) { (body, response, error ) in

                    if expectError {
                        XCTAssertNil(body)
                        XCTAssertNil(response)
                        XCTAssertNotNil(error)
                    } else {
                        XCTAssertNil(error)
                        let response = response as? HTTPURLResponse
                        XCTAssertNotNil(response)

                        let statusCode = response?.statusCode
                        XCTAssertNotNil(statusCode)
                        XCTAssertEqual(statusCode, 200)
                    #if !os(Linux)
                        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, *) {
                            let header = response?.value(forHTTPHeaderField: "XXX-Custom-Header") ?? ""
                            XCTAssertEqual(header, testString)
                        }
                    #endif

                        XCTAssertEqual(body, testString.data(using: .utf8))
                    }

                    requestExpectation?.fulfill()
                    requestExpectation = nil
                }

                task.resume()
            }

        } catch let error {
            XCTFail("\(error)")
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testRawResponseWithBodyWriter() {

        let testString = "normal"

        let handler: ((HttpRequest) -> HttpResponse)  = { _ in
            return HttpResponse.raw(200, "OK", ["XXX-Custom-Header": testString], {
                try $0.write([UInt8]((testString) .utf8))
            })
        }

        doHandlerTest(handler: handler, testString: testString)
    }

    func testFailedUnboundedResponseShouldNotHang() {

        let testString = "unbounded"
        let handler: ((HttpRequest) -> HttpResponse)  = { _ in
            return HttpResponse.raw(200, "OK", ["XXX-Custom-Header": testString], {
                try $0.write([UInt8]((testString) .utf8))

                // simulates the body writer not being able to finish the body.
                throw TestError.aborted
            })
        }

        doHandlerTest(handler: handler, testString: testString)
    }

    func testFailedBoundedResponseShouldNotHang() {

        let testString = "bounded"   // content-length: 7
        let handler: ((HttpRequest) -> HttpResponse)  = { _ in
            return HttpResponse.raw(200, "OK", [
                "XXX-Custom-Header": testString,
                "Content-Length": "\(testString.utf8.count+1)"  // we'll be missing one byte
            ], {
                try $0.write([UInt8]((testString) .utf8))

                throw TestError.aborted
            })
        }

        // because the length is known, we should trigger a network failure
        doHandlerTest(handler: handler, testString: testString, expectError: true)
    }
}

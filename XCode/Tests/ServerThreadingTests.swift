//
//  ServerThreadingTests.swift
//  Swifter
//
//  Created by Victor Sigler on 4/22/19.
//  Copyright © 2019 Damian Kołakowski. All rights reserved.
//

import XCTest
#if os(Linux)
import FoundationNetworking
#endif
@testable import Swifter

class ServerThreadingTests: XCTestCase {

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

    func testShouldHandleTheRequestInDifferentTimeIntervals() {

        let path = "/a/:b/c"
        let queue = DispatchQueue(label: "com.swifter.threading")
        let hostURL: URL

        server.GET[path] = { .ok(.htmlBody("You asked for " + $0.path)) }

        do {

            #if os(Linux)
            try server.start(9081)
            hostURL = URL(string: "http://localhost:9081")!
            #else
            try server.start()
            hostURL = defaultLocalhost
            #endif

            let requestExpectation = expectation(description: "Request should finish.")
            requestExpectation.expectedFulfillmentCount = 3

            (1...3).forEach { index in
                queue.asyncAfter(deadline: .now() + .seconds(index)) {
                    let task = URLSession.shared.executeAsyncTask(hostURL: hostURL, path: path) { (_, response, _ ) in
                        requestExpectation.fulfill()
                        let statusCode = (response as? HTTPURLResponse)?.statusCode
                        XCTAssertNotNil(statusCode)
                        XCTAssertEqual(statusCode, 200, "\(hostURL)")
                    }

                    task.resume()
                }
            }

        } catch let error {
            XCTFail("\(error)")
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testShouldHandleTheSameRequestConcurrently() {

        let path = "/a/:b/c"
        server.GET[path] = { .ok(.htmlBody("You asked for " + $0.path)) }

        var requestExpectation: XCTestExpectation? = expectation(description: "Should handle the request concurrently")

        do {

            try server.start()
            let downloadGroup = DispatchGroup()

            DispatchQueue.concurrentPerform(iterations: 3) { _ in
                downloadGroup.enter()

                let task = URLSession.shared.executeAsyncTask(path: path) { (_, response, _ ) in

                    let statusCode = (response as? HTTPURLResponse)?.statusCode
                    XCTAssertNotNil(statusCode)
                    XCTAssertEqual(statusCode, 200)
                    requestExpectation?.fulfill()
                    requestExpectation = nil
                    downloadGroup.leave()
                }

                task.resume()
            }

        } catch let error {
            XCTFail("\(error)")
        }

        waitForExpectations(timeout: 15, handler: nil)
    }
}

extension URLSession {

    func executeAsyncTask(
        hostURL: URL = defaultLocalhost,
        path: String,
        completionHandler handler: @escaping (Data?, URLResponse?, Error?) -> Void
        ) -> URLSessionDataTask {
        return self.dataTask(with: hostURL.appendingPathComponent(path), completionHandler: handler)
    }
}

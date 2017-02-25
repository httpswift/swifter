//
//  SwifterTests.swift
//  SwifterTests
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest

class SwifterTestsHttpParser: XCTestCase {
    
    func testRandomStuff() {
        do {
            let data = [UInt8]("1231245".utf8)
            try HttpIncomingDataPorcessor(0, { item in
                XCTAssert(false, "Http processor should not return a request object for invalid data .")
            }).process(data[0..<data.count])
        } catch {
            XCTAssert(false, "No exception")
        }
    }
    
    func testInvalidStatusLineChunk() {
        do {
            let data = [UInt8]("GET HTTP/1.0".utf8)
            try HttpIncomingDataPorcessor(0, { item in
                XCTAssert(false, "Http processor should not return a request object for invalid status line.")
            }).process(data[0..<data.count])
        } catch {
            XCTAssert(false, "No exception")
        }
    }
    
    func testValidStatusLineChunk() {
        do {
            let data = [UInt8]("GET / HTTP/1.0".utf8)
            try HttpIncomingDataPorcessor(0, { item in
                XCTAssert(false, "Http processor should not return a request object for valid status line only.")
            }).process(data[0..<data.count])
        } catch {
            XCTAssert(false, "No exception")
        }
    }
    
    func testStatusLineWithSingleNextLine() {
        do {
            let data = [UInt8]("GET / HTTP/1.0\r\n".utf8)
            try HttpIncomingDataPorcessor(0, { item in
                XCTAssert(false, "Http processor should not return if there is no double next line symbol.")
            }).process(data[0..<data.count])
        } catch {
            XCTAssert(false, "No exception")
        }
    }
    
    func testStatusLineWithDoubleNextLine() {
        do {
            var request: Request? = nil
            let data = [UInt8]("GET / HTTP/1.0\r\n\r\n".utf8)
            try HttpIncomingDataPorcessor(0, { item in
                request = item
            }).process(data[0..<data.count])
            XCTAssertEqual(request?.path, "/")
            XCTAssertEqual(request?.method, "GET")
            XCTAssertEqual(request?.httpVersion, .http10)
        } catch {
            XCTAssert(false, "There should be no crash for valid http request.")
        }
    }
    
    func testContentLengthZero() {
        do {
            var request: Request? = nil
            let data = [UInt8]("GET / HTTP/1.0\r\nContent-Length: 0\r\n\r\n".utf8)
            try HttpIncomingDataPorcessor(0, { item in
                request = item
            }).process(data[0..<data.count])
            XCTAssertEqual(request?.path, "/")
            XCTAssertEqual(request?.method, "GET")
            XCTAssertEqual(request?.body.count, 0)
            XCTAssertEqual(request?.httpVersion, .http10)
        } catch {
            XCTAssert(false, "No exception")
        }
    }
    
    func testContentLengthNonZero() {
        do {
            var request: Request? = nil
            let data = [UInt8]("GET / HTTP/1.0\r\nContent-Length: 5\r\n\r\n12345".utf8)
            try HttpIncomingDataPorcessor(0, { item in
                request = item
            }).process(data[0..<data.count])
            XCTAssertEqual(request?.path, "/")
            XCTAssertEqual(request?.method, "GET")
            XCTAssertEqual(request?.body.count, 5)
            XCTAssertEqual((request?.body)!, [49, 50, 51, 52, 53])
            XCTAssertEqual(request?.httpVersion, .http10)
        } catch {
            XCTAssert(false, "No exception")
        }
    }
    
    func testContentLengthWithBodyChunk() {
        do {
            var request: Request? = nil
            let data = [UInt8]("GET / HTTP/1.0\r\nContent-Length: 10\r\n\r\n123".utf8)
            try HttpIncomingDataPorcessor(0, { item in
                request = item
            }).process(data[0..<data.count])
            XCTAssertNil(request)
        } catch {
            XCTAssert(false, "No exception")
        }
    }
    
    func testContentProcessedInChunks() {
        do {
            var request: Request? = nil
            
            let processor = HttpIncomingDataPorcessor(0, { item in
                request = item
            })
            
            let chunk1 = [UInt8]("GET /chunk HTTP/1.0\r\nContent-Length: 20\r\n\r\n123".utf8)
            try processor.process(chunk1[0..<chunk1.count])
            
            XCTAssertNil(request)
            
            let chunk2 = [UInt8]("1234567890".utf8)
            try processor.process(chunk2[0..<chunk2.count])
            
            XCTAssertNil(request)
            
            let chunk3 = [UInt8]("1234567".utf8)
            try processor.process(chunk3[0..<chunk3.count])
            
            XCTAssertEqual(request?.path, "/chunk")
            XCTAssertEqual(request?.method, "GET")
            XCTAssertEqual(request?.body.count, 20)
            XCTAssertEqual(request?.httpVersion, .http10)
            
        } catch {
            XCTAssert(false, "No exception")
        }
    }
    
    func testHeaders() {
        do {
            var request: Request? = nil
            let data = [UInt8]("GET / HTTP/1.0\r\na: b\r\nc: d\r\nContent-Length: 0\r\n\r\n".utf8)
            try HttpIncomingDataPorcessor(0, { item in
                request = item
            }).process(data[0..<data.count])
            XCTAssertNotNil(request)
            XCTAssertEqual(request?.headers.first?.0, "a")
            XCTAssertEqual(request?.headers.first?.1, "b")
            XCTAssertEqual(request?.headers[1].0, "c")
            XCTAssertEqual(request?.headers[1].1, "d")
        } catch {
            XCTAssert(false, "No exception")
        }
    }
    
    func testPath() {
        do {
            var request: Request? = nil
            let data = [UInt8]("GET /a/b/c/d?1345678=1231 HTTP/1.0\r\nContent-Length: 0\r\n\r\n".utf8)
            try HttpIncomingDataPorcessor(0, { item in
                request = item
            }).process(data[0..<data.count])
            XCTAssertEqual(request?.path, "/a/b/c/d")
            XCTAssertEqual(request?.method, "GET")
            XCTAssertEqual(request?.body.count, 0)
            XCTAssertEqual(request?.httpVersion, .http10)
        } catch {
            XCTAssert(false, "No exception")
        }
    }
    
    func testPathWithComplexQuery() {
        do {
            var request: Request? = nil
            let data = [UInt8]("GET /a/b/c/d?key=value1?&key=???s HTTP/1.0\r\nContent-Length: 0\r\n\r\n".utf8)
            try HttpIncomingDataPorcessor(0, { item in
                request = item
            }).process(data[0..<data.count])
            XCTAssertEqual(request?.path, "/a/b/c/d")
            XCTAssertEqual(request?.method, "GET")
            XCTAssertEqual(request?.query[0].0, "key")
            XCTAssertEqual(request?.query[0].1, "value1?")
            XCTAssertEqual(request?.query[1].0, "key")
            XCTAssertEqual(request?.query[1].1, "???s")
            XCTAssertEqual(request?.body.count, 0)
            XCTAssertEqual(request?.httpVersion, .http10)
        } catch {
            XCTAssert(false, "No exception")
        }
    }
}

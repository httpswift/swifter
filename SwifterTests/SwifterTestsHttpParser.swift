//
//  SwifterTests.swift
//  SwifterTests
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest

import Swifter

class SwifterTestsHttpParser: XCTestCase {
    
    class TestSocket: Socket {
        var content = [UInt8]()
        var offset = 0
        
        init(_ content: String) {
            super.init(socketFileDescriptor: -1)
            self.content.appendContentsOf([UInt8](content.utf8))
        }

        override func read() throws -> UInt8 {
            if offset < content.count {
                let value = self.content[offset]
                offset = offset + 1
                return value
            }
            throw SocketError.RecvFailed("")
        }
    }
    
    func testParser() {
        let parser = HttpParser()
        
        do {
            try parser.readHttpRequest(TestSocket(""))
            XCTAssertTrue(false, "Parser should throw an error if socket is empty.")
        } catch { }

        do {
            try parser.readHttpRequest(TestSocket("12345678"))
            XCTAssertTrue(false, "Parser should throw an error if status line has single token.")
        } catch { }

        do {
            try parser.readHttpRequest(TestSocket("GET HTTP/1.0"))
            XCTAssertTrue(false, "Parser should throw an error if status line has not enough tokens.")
        } catch { }

        do {
            try parser.readHttpRequest(TestSocket("GET / HTTP/1.0"))
            XCTAssertTrue(false, "Parser should throw an error if there is no next line symbol.")
        } catch { }
            
        do {
            try parser.readHttpRequest(TestSocket("GET / HTTP/1.0"))
            XCTAssertTrue(false, "Parser should throw an error if there is no next line symbol.")
        } catch { }
        
        do {
            try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\r"))
            XCTAssertTrue(false, "Parser should throw an error if there is no next line symbol.")
        } catch { }
        
        do {
            try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\n"))
            XCTAssertTrue(false, "Parser should throw an error if there is no 'Content-Length' header.")
        } catch { }
        
        do {
            try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\r\nContent-Length: 0\r\n\r\n"))
        } catch {
            XCTAssertTrue(false, "Parser should not throw any errors if there is a valid 'Content-Length' header.")
        }
        
        do {
            try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nContent-Length: 0\r\n\n"))
        } catch {
            XCTAssertTrue(false, "Parser should not throw any errors if there is a valid 'Content-Length' header.")
        }
        
        do {
            try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nContent-Length: 5\n\n12345"))
        } catch {
            XCTAssertTrue(false, "Parser should not throw any errors if there is a valid 'Content-Length' header.")
        }
        
        do {
            try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nContent-Length: 10\r\n\n"))
            XCTAssertTrue(false, "Parser should throw an error if request' body is too short.")
        } catch { }
        
        var r = try? parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nContent-Length: 10\n\n1234567890"))
        XCTAssertTrue(r?.method == "GET", "Parser should extract HTTP method name from the status line.")
        XCTAssertTrue(r?.path == "/", "Parser should extract HTTP path value from the status line.")
        XCTAssertTrue(r?.headers["content-length"] == "10", "Parser should extract Content-Length header value.")
        
        r = try? parser.readHttpRequest(TestSocket("POST / HTTP/1.0\nContent-Length: 10\n\n1234567890"))
        XCTAssertTrue(r?.method == "POST", "Parser should extract HTTP method name from the status line.")
        
        r = try? parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nHeader1: 1\nHeader2: 2\nContent-Length: 0\n\n"))
        XCTAssertTrue(r?.headers["header1"] == "1", "Parser should extract multiple headers from the request.")
        XCTAssertTrue(r?.headers["header2"] == "2", "Parser should extract multiple headers from the request.")
    }
}
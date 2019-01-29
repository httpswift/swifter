//
//  SwifterTests.swift
//  SwifterTests
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest
@testable import Swifter

class SwifterTestsHttpParser: XCTestCase {
    
    /// A specialized Socket which creates a linked socket pair with a pipe, and
    /// immediately writes in fixed data. This enables tests to static fixture
    /// data into the regular Socket flow.
    class TestSocket: Socket {
        init(_ content: String) {
            /// Create an array to hold the read and write sockets that pipe creates
            var fds = [Int32](repeating: 0, count: 2)
            fds.withUnsafeMutableBufferPointer { ptr in
                let rv = pipe(ptr.baseAddress!)
                guard rv >= 0 else { fatalError("Pipe error!") }
            }

            // Extract the read and write handles into friendly variables
            let fdRead = fds[0]
            let fdWrite = fds[1]

            // Set non-blocking I/O on both sockets. This is required!
            _ = fcntl(fdWrite, F_SETFL, O_NONBLOCK)
            _ = fcntl(fdRead, F_SETFL, O_NONBLOCK)

            // Push the content bytes into the write socket.
            _ = content.withCString { stringPointer in
                // Count will be either >=0 to indicate bytes written, or -1
                // if the bytes will be written later (non-blocking).
                let count = write(fdWrite, stringPointer, content.lengthOfBytes(using: .utf8) + 1)
                guard count != -1 || errno == EAGAIN else { fatalError("Write error!") }
            }

            // Close the write socket immediately. The OS will add an EOF byte
            // and the read socket will remain open.
            #if os(Linux)
            Glibc.close(fdWrite)
            #else
            Darwin.close(fdWrite) // the super instance will close fdRead in deinit!
            #endif
            
            super.init(socketFileDescriptor: fdRead)
        }
    }

    func testParser() {
        let parser = HttpParser()
        
        do {
            let _ = try parser.readHttpRequest(TestSocket(""))
            XCTAssert(false, "Parser should throw an error if socket is empty.")
        } catch { }
        
        do {
            let _ = try parser.readHttpRequest(TestSocket("12345678"))
            XCTAssert(false, "Parser should throw an error if status line has single token.")
        } catch { }
        
        do {
            let _ = try parser.readHttpRequest(TestSocket("GET HTTP/1.0"))
            XCTAssert(false, "Parser should throw an error if status line has not enough tokens.")
        } catch { }
        
        do {
            let _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0"))
            XCTAssert(false, "Parser should throw an error if there is no next line symbol.")
        } catch { }
        
        do {
            let _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0"))
            XCTAssert(false, "Parser should throw an error if there is no next line symbol.")
        } catch { }
        
        do {
            let _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\r"))
            XCTAssert(false, "Parser should throw an error if there is no next line symbol.")
        } catch { }
        
        do {
            let _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\n"))
            XCTAssert(false, "Parser should throw an error if there is no 'Content-Length' header.")
        } catch { }
        
        do {
            let _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\r\nContent-Length: 0\r\n\r\n"))
        } catch {
            XCTAssert(false, "Parser should not throw any errors if there is a valid 'Content-Length' header.")
        }
        
        do {
            let _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nContent-Length: 0\r\n\n"))
        } catch {
            XCTAssert(false, "Parser should not throw any errors if there is a valid 'Content-Length' header.")
        }
        
        do {
            let _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nContent-Length: 5\n\n12345"))
        } catch {
            XCTAssert(false, "Parser should not throw any errors if there is a valid 'Content-Length' header.")
        }
        
        do {
            let _ = try parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nContent-Length: 10\r\n\n"))
            XCTAssert(false, "Parser should throw an error if request' body is too short.")
        } catch { }

        do { // test payload less than 1 read segmant
            let contentLength = Socket.kBufferLength - 128
            let bodyString = [String](repeating: "A", count: contentLength).joined(separator: "")

            let payload = "GET / HTTP/1.0\nContent-Length: \(contentLength)\n\n".appending(bodyString)
            let request = try parser.readHttpRequest(TestSocket(payload))

            XCTAssert(bodyString.lengthOfBytes(using: .utf8) == contentLength, "Has correct request size")

            let unicodeBytes = bodyString.utf8.map { return $0 }
            XCTAssert(request.body == unicodeBytes, "Request body must be correct")
        } catch { }

        do { // test payload equal to 1 read segmant
            let contentLength = Socket.kBufferLength
            let bodyString = [String](repeating: "B", count: contentLength).joined(separator: "")
            let payload = "GET / HTTP/1.0\nContent-Length: \(contentLength)\n\n".appending(bodyString)
            let request = try parser.readHttpRequest(TestSocket(payload))

            XCTAssert(bodyString.lengthOfBytes(using: .utf8) == contentLength, "Has correct request size")

            let unicodeBytes = bodyString.utf8.map { return $0 }
            XCTAssert(request.body == unicodeBytes, "Request body must be correct")
        } catch { }

        do { // test very large multi-segment payload
            let contentLength = Socket.kBufferLength * 4
            let bodyString = [String](repeating: "C", count: contentLength).joined(separator: "")
            let payload = "GET / HTTP/1.0\nContent-Length: \(contentLength)\n\n".appending(bodyString)
            let request = try parser.readHttpRequest(TestSocket(payload))

            XCTAssert(bodyString.lengthOfBytes(using: .utf8) == contentLength, "Has correct request size")

            let unicodeBytes = bodyString.utf8.map { return $0 }
            XCTAssert(request.body == unicodeBytes, "Request body must be correct")
        } catch { }
        
        var r = try? parser.readHttpRequest(TestSocket("GET /open?link=https://www.youtube.com/watch?v=D2cUBG4PnOA HTTP/1.0\nContent-Length: 10\n\n1234567890"))
        
        XCTAssertEqual(r?.queryParams.filter({ $0.0 == "link"}).first?.1, "https://www.youtube.com/watch?v=D2cUBG4PnOA")
        XCTAssertEqual(r?.method, "GET", "Parser should extract HTTP method name from the status line.")
        XCTAssertEqual(r?.path, "/open?link=https://www.youtube.com/watch?v=D2cUBG4PnOA", "Parser should extract HTTP path value from the status line.")
        XCTAssertEqual(r?.headers["content-length"], "10", "Parser should extract Content-Length header value.")
        
        r = try? parser.readHttpRequest(TestSocket("POST / HTTP/1.0\nContent-Length: 10\n\n1234567890"))
        XCTAssertEqual(r?.method, "POST", "Parser should extract HTTP method name from the status line.")
        
        r = try? parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nHeader1: 1:1:34\nHeader2: 12345\nContent-Length: 0\n\n"))
        XCTAssertEqual(r?.headers["header1"], "1:1:34", "Parser should properly extract header name and value in case the value has ':' character.")
        
        r = try? parser.readHttpRequest(TestSocket("GET / HTTP/1.0\nHeader1: 1\nHeader2: 2\nContent-Length: 0\n\n"))
        XCTAssertEqual(r?.headers["header1"], "1", "Parser should extract multiple headers from the request.")
        XCTAssertEqual(r?.headers["header2"], "2", "Parser should extract multiple headers from the request.")
    }
}

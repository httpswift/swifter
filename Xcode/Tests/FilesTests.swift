//
//  FilesTests.swift
//  Swifter
//
//  Created by Michael Enger on 02/09/2021.
//  Copyright © 2021 Damian Kołakowski. All rights reserved.
//

import XCTest
#if os(Linux)
import FoundationNetworking
#endif
@testable import Swifter

class FilesTests: XCTestCase {
    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
    let temporaryFileName = UUID().uuidString + ".png"

    override func setUp() {
        super.setUp()

        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFileName)
        let data = "This is a file"
        do {
            try data.write(to: temporaryFileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            XCTFail("Failed to create temporary file")
        }
    }

    override func tearDown() {
        let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(temporaryFileName)
        do {
            try FileManager.default.removeItem(at: temporaryFileURL)
        } catch {
            // no worries
        }
        
        super.tearDown()
    }
    
    func testShareFile() {
        let request = HttpRequest()
        let closure = shareFile(temporaryDirectoryURL.appendingPathComponent(temporaryFileName).path)
        let result = closure(request)
        let headers = result.headers()

        XCTAssert(result.statusCode == 200)
        XCTAssert(headers["Content-Type"] == "image/png")
        XCTAssert(headers["Content-Length"] == "14")
    }
    
    func testShareFileNotFound() {
        let request = HttpRequest()
        let closure = shareFile(temporaryDirectoryURL.appendingPathComponent("does_not_exist").path)
        let result = closure(request)

        XCTAssert(result == .notFound())
    }

    func testShareFilesFromDirectory() {
        let request = HttpRequest()
        request.params = ["path": temporaryFileName]
        let closure = shareFilesFromDirectory(temporaryDirectoryURL.path)
        let result = closure(request)
        let headers = result.headers()

        XCTAssert(result.statusCode == 200)
        XCTAssert(headers["Content-Type"] == "image/png")
        XCTAssert(headers["Content-Length"] == "14")
    }
    
    func testShareFilesFromDirectoryFileNotFound() {
        let request = HttpRequest()
        request.params = ["path": "does_not_exist.wav"]

        let closure = shareFilesFromDirectory(temporaryDirectoryURL.path)
        let result = closure(request)

        XCTAssert(result == .notFound())
    }
    
    func testDirectoryBrowser() {
        let request = HttpRequest()
        request.params = ["path": ""]
        let closure = directoryBrowser(temporaryDirectoryURL.path)
        let result = closure(request)

        XCTAssert(result.statusCode == 200)
    }
    
    func testDirectoryBrowserNotFound() {
        let request = HttpRequest()
        request.params = ["path": "does/not/exist"]
        let closure = directoryBrowser(temporaryDirectoryURL.path)
        let result = closure(request)

        XCTAssert(result == .notFound())
    }
}

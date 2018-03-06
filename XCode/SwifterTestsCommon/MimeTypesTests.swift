//
//  MimeTypesTests.swift
//  Swifter
//
//  Created by Daniel Große on 06.03.18.
//  Copyright © 2018 Damian Kołakowski. All rights reserved.
//

import XCTest

class MimeTypeTests: XCTestCase {

    func testTypeExtension() {
        XCTAssertNotNil(String.mimeType, "Type String is extended with mimeType")
        XCTAssertNotNil(NSURL.mimeType, "Type NSURL is extended with mimeType")
        XCTAssertNotNil(NSString.mimeType, "Type NSString is extended with mimeType")
    }
    
    func testDefaultValue() {
        XCTAssertEqual("file.null".mimeType(), "application/octet-stream")
    }
    
    func testCorrectTypes() {
        XCTAssertEqual("file.html".mimeType(), "text/html")
        XCTAssertEqual("file.css".mimeType(), "text/css")
        XCTAssertEqual("file.mp4".mimeType(), "video/mp4")
        XCTAssertEqual("file.pptx".mimeType(), "application/vnd.openxmlformats-officedocument.presentationml.presentation")
        XCTAssertEqual("file.war".mimeType(), "application/java-archive")
    }
    
    func testCaseInsensitivity() {
        XCTAssertEqual("file.HTML".mimeType(), "text/html")
        XCTAssertEqual("file.cSs".mimeType(), "text/css")
        XCTAssertEqual("file.MP4".mimeType(), "video/mp4")
        XCTAssertEqual("file.PPTX".mimeType(), "application/vnd.openxmlformats-officedocument.presentationml.presentation")
        XCTAssertEqual("FILE.WAR".mimeType(), "application/java-archive")
    }
  
}


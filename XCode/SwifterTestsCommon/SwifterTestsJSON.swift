//
//  SwifterTestsJSON.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest
import Swifter

class SwifterTestsSwfitJSON: XCTestCase {
    
    func testJSONStringEscape() {
        
        XCTAssertEqual("".asJson(0), "\"\"")
        XCTAssertEqual("\"".asJson(0), "\"\\\"\"")
        XCTAssertEqual("\\".asJson(0), "\"\\\\\"")
        XCTAssertEqual("/".asJson(0), "\"\\/\"")
        
        XCTAssertEqual("\u{8}".asJson(0), "\"\\b\"")
        XCTAssertEqual("\u{0C}".asJson(0), "\"\\f\"")
        XCTAssertEqual("\r".asJson(0), "\"\\r\"")
        XCTAssertEqual("\n".asJson(0), "\"\\n\"")
        XCTAssertEqual("\t".asJson(0), "\"\\t\"")
        
        XCTAssertEqual("ę".asJson(0), "\"\\u0119\"")
        XCTAssertEqual("한".asJson(0), "\"\\uD55C\"")
        XCTAssertEqual("💖".asJson(0), "\"\\u1F496\"")
        XCTAssertEqual("🐪".asJson(0), "\"\\u1F42A\"")
        
        // From Ruby: https://github.com/ruby/ruby/blob/trunk/test/json/json_encoding_test.rb
        
        XCTAssertEqual("© ≠ €!".asJson(0), "\"\\u00A9 \\u2260 \\u20AC!\"")
    }
    
    func testJSONNumber() {
        XCTAssertEqual(0.asJson(0), "0")
        XCTAssertEqual(1.asJson(0), "1")
        XCTAssertEqual(99999.asJson(0), "99999")
        
        XCTAssertEqual((1.01).asJson(0), "1.01")
        XCTAssertEqual((1.0).asJson(0), "1.0")
        XCTAssertEqual(Double(1.01).asJson(0), "1.01")
    }

    
    func testJSONBool() {
        XCTAssertEqual(true.asJson(0), "true")
        XCTAssertEqual(false.asJson(0), "false")
    }

    
    func testJSONObject() {
        XCTAssertEqual([1, 2].asJson(0), "[1,2]")
        XCTAssertEqual(["key1" : [1, 2]].asJson(0), "{\"key1\":[1,2]}")
        XCTAssertEqual(["key1" : ["key2": ["key3": false]]].asJson(0), "{\"key1\":{\"key2\":{\"key3\":false}}}")
        XCTAssertEqual(["key1" : ["key2": ["key3": false, "key4": 1]]].asJson(0), "{\"key1\":{\"key2\":{\"key4\":1,\"key3\":false}}}")
    }
    
}

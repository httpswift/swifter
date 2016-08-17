//
//  SwifterTestsJSON.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest

class SwifterTestsSwfitJSON: XCTestCase {
    
    func testJSONObject() {
        
        var array = [Any?]()
        array.append(nil)
        XCTAssertEqual(array.asJson(), "[null]")
        
        XCTAssertEqual([1, false].asJson(), "[1,false]")
        XCTAssertEqual([1, 2].asJson(), "[1,2]")
        XCTAssertEqual(["key1" : [1, 2]].asJson(), "{\"key1\":[1,2]}")
        XCTAssertEqual(["key1" : ["key2": ["key3": false]]].asJson(), "{\"key1\":{\"key2\":{\"key3\":false}}}")
        XCTAssertEqual(["key1" : ["key2": ["key3": false, "key4": 1]]].asJson(), "{\"key1\":{\"key2\":{\"key4\":1,\"key3\":false}}}")
    }
    
}

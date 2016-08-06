//
//  SwiferTestsRSA.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest
import Swifter

class SwifterTestsRSA: XCTestCase {
    
    func testRSA() {
        
        let config = RSA.config(7, 11)
        
        XCTAssertEqual(RSA.encrypt(6, config), 41)
        
        XCTAssertEqual(RSA.decrypt(RSA.encrypt(6, config), config), 6)
    }
}

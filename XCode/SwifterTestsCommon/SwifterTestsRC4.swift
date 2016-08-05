//
//  SwifterTestsRC4.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest
import Swifter

class SwifterTestsRC4: XCTestCase {
    
    func testRC4() {
        
        let encrypted = RC4.encrypt([UInt8]("Plaintext".utf8), [UInt8]("Key".utf8))
        
        XCTAssertTrue(encrypted == [0xbb, 0xf3, 0x16, 0xe8, 0xd9, 0x40, 0xaf, 0x0a, 0xd3])
        
        let decrypted = RC4.decrypt([0xbb, 0xf3, 0x16, 0xe8, 0xd9, 0x40, 0xaf, 0x0a, 0xd3], [UInt8]("Key".utf8))
        
        XCTAssertTrue(decrypted == [UInt8]("Plaintext".utf8))
    }
}

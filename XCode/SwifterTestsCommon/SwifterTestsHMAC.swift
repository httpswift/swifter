//
//  SwifterTestsHMAC.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest

class SwifterTestsHMAC: XCTestCase {
    
    func testSHA1() {
        
        XCTAssertEqual(HMAC.sha1([UInt8]("".utf8), [UInt8]("".utf8)), "fbdb1d1b18aa6c08324b7d64b71fb76370690e1d")
        XCTAssertEqual(HMAC.sha1([UInt8]("key".utf8), [UInt8]("The quick brown fox jumps over the lazy dog".utf8)),
                       "de7c9b85b8b78aa6bc8a7a36f70a90701c9db4d9")
    }
    
    func testSHA256() {
        
        XCTAssertEqual(HMAC.sha256([UInt8]("".utf8), [UInt8]("".utf8)), "b613679a0814d9ec772f95d778c35fc5ff1697c493715653c6c712144292c5ad")

        XCTAssertEqual(HMAC.sha256([UInt8]("key".utf8), [UInt8]("The quick brown fox jumps over the lazy dog".utf8)), "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8")
    }
    
    func testMD5() {
        
        XCTAssertEqual(HMAC.md5([UInt8]("".utf8), [UInt8]("".utf8)), "74e6f7298a9c2d168935f58c001bad88")
        XCTAssertEqual(HMAC.md5([UInt8]("key".utf8), [UInt8]("The quick brown fox jumps over the lazy dog".utf8)),
                       "80070713463e7749b90c2dc24911e275")
    }
}

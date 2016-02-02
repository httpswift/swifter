//
//  SwifterTests.swift
//  SwifterTests
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest

import Swifter

class SwifterTestsStringExtensions: XCTestCase {
    
    func testSHA1() {
        XCTAssertEqual("".SHA1(), "da39a3ee5e6b4b0d3255bfef95601890afd80709")
        XCTAssertEqual("test".SHA1(), "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
        
        // Values copied from OpenSSL:
        // https://github.com/openssl/openssl/blob/master/test/sha1test.c
        
        XCTAssertEqual("abc".SHA1(), "a9993e364706816aba3e25717850c26c9cd0d89d")
        XCTAssertEqual("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq".SHA1(),
            "84983e441c3bd26ebaae4aa1f95129e5e54670f1")
    }
    
    func testBASE64() {
        XCTAssertEqual(String.toBase64([UInt8]("".utf8)), "")
        
        // Values copied from OpenSSL:
        // https://github.com/openssl/openssl/blob/995197ab84901df1cdf83509c4ce3511ea7f5ec0/test/evptests.txt
        
        XCTAssertEqual(String.toBase64([UInt8]("h".utf8)), "aA==")
        XCTAssertEqual(String.toBase64([UInt8]("hello".utf8)), "aGVsbG8=")
        XCTAssertEqual(String.toBase64([UInt8]("hello world!".utf8)), "aGVsbG8gd29ybGQh")
        XCTAssertEqual(String.toBase64([UInt8]("OpenSSLOpenSSL\n".utf8)), "T3BlblNTTE9wZW5TU0wK")
        XCTAssertEqual(String.toBase64([UInt8]("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx".utf8)),
            "eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eHh4eA==")
        XCTAssertEqual(String.toBase64([UInt8]("h".utf8)), "aA==")
    }

}

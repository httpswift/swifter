//
//  SwifterTests.swift
//  SwifterTests
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest

class SwifterTestsStringExtensions: XCTestCase {
    
    func testSHA1() {
        XCTAssertEqual("".sha1(), "da39a3ee5e6b4b0d3255bfef95601890afd80709")
        XCTAssertEqual("test".sha1(), "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3")
        
        // Values copied from OpenSSL:
        // https://github.com/openssl/openssl/blob/master/test/sha1test.c
        
        XCTAssertEqual("abc".sha1(), "a9993e364706816aba3e25717850c26c9cd0d89d")
        XCTAssertEqual("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq".sha1(),
            "84983e441c3bd26ebaae4aa1f95129e5e54670f1")
        
        XCTAssertEqual(
            ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" +
             "a9993e364706816aba3e25717850c26c9cd0d89d" +
             "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" +
             "a9993e364706816aba3e25717850c26c9cd0d89d" +
             "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" +
             "a9993e364706816aba3e25717850c26c9cd0d89d" +
             "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" +
             "a9993e364706816aba3e25717850c26c9cd0d89d" +
             "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" +
             "a9993e364706816aba3e25717850c26c9cd0d89d" +
             "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq" +
             "a9993e364706816aba3e25717850c26c9cd0d89d" +
             "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq").sha1(),
            "a377b0c42d685fdc396e29a9eda7101d900947ca")
    }
    
    func testSHA256() {
        XCTAssertEqual("".sha256(), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssertEqual("abc".sha256(), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        XCTAssertEqual("hello".sha256(), "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
        
        XCTAssertEqual("hello".sha256(), "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824")
        XCTAssertEqual("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla ornare orci in metus egestas, sed ornare ante sagittis. Etiam pellentesque mauris ac tincidunt interdum. Mauris nec arcu non dolor venenatis placerat. Pellentesque condimentum feugiat lacus ac maximus. Fusce ut nibh lobortis, porta eros ut, rhoncus tellus. Suspendisse nec molestie quam. Nunc dapibus quam felis, viverra blandit nisi auctor quis. Fusce nisl ante, interdum sed congue ac, ullamcorper sit amet purus. Curabitur vestibulum commodo lobortis.".sha256(), "ea7da36063c95f557374fe98975f0b3cab900772c019747918232a0c0127e6db")
    }
    
    func testMD5() {
        
        // Values from: https://tools.ietf.org/html/rfc1321
        
        XCTAssertEqual("".md5(), "d41d8cd98f00b204e9800998ecf8427e")
        
        XCTAssertEqual("The quick brown fox jumps over the lazy dog.".md5(), "e4d909c290d0fb1ca068ffaddf22cbd0")
        
        XCTAssertEqual("a".md5(), "0cc175b9c0f1b6a831c399e269772661")
        
        XCTAssertEqual("abc".md5(), "900150983cd24fb0d6963f7d28e17f72")
        
        XCTAssertEqual("message digest".md5(), "f96b697d7cb7938d525a2f31aaf161d0")
        
        XCTAssertEqual("abcdefghijklmnopqrstuvwxyz".md5(), "c3fcd3d76192e4007dfb496cca67e13b")
        
        XCTAssertEqual("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".md5(), "d174ab98d277d9f5a5611c2c9f419d9f")
        
        XCTAssertEqual("12345678901234567890123456789012345678901234567890123456789012345678901234567890".md5(), "57edf4a22be3c955ac49da2e2107b67a")
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
    
    func testMiscUnquote() {
        XCTAssertEqual("".unquote(), "")
        XCTAssertEqual("\"".unquote(), "\"")
        XCTAssertEqual("\"\"".unquote(), "")
        
        XCTAssertEqual("1234".unquote(), "1234")
        XCTAssertEqual("1234\"".unquote(), "1234\"")
        XCTAssertEqual("\"1234".unquote(), "\"1234")
        XCTAssertEqual("\"1234\"".unquote(), "1234")
        XCTAssertEqual("\"1234\"".unquote(), "1234")
        
        XCTAssertEqual("\"\"\"".unquote(), "\"")
        XCTAssertEqual("\"\" \"\"".unquote(), "\" \"")
    }
    
    func testMiscTrim() {
        XCTAssertEqual("".trim(), "")
        XCTAssertEqual("\n".trim(), "")
        XCTAssertEqual("\t".trim(), "")
        XCTAssertEqual("\r".trim(), "")
        XCTAssertEqual(" ".trim(), "")
        XCTAssertEqual("      ".trim(), "")
        XCTAssertEqual("1 test     ".trim(), "1 test")
        XCTAssertEqual("      test          ".trim(), "test")
        XCTAssertEqual("   \t\n\rtest          ".trim(), "test")
        XCTAssertEqual("   \t\n\rtest  n   \n\t asd    ".trim(), "test  n   \n\t asd")
    }

    func testMiscReplace() {
        XCTAssertEqual("".replace("+", "-"), "")
        XCTAssertEqual("test".replace("+", "-"), "test")
        XCTAssertEqual("+++".replace("+", "-"), "---")
        XCTAssertEqual("t&e&s&t12%3%".replace("&", "+").replace("%", "+"), "t+e+s+t12+3+")
        XCTAssertEqual("test 1234 #$%^&*( test   ".replace(" ", "_"), "test_1234_#$%^&*(_test___")
    }
    
    func testMiscRemovePercentEncoding() {
        XCTAssertEqual("".removePercentEncoding(), "")
        XCTAssertEqual("%20".removePercentEncoding(), " ")
        XCTAssertEqual("%22".removePercentEncoding(), "\"")
        XCTAssertEqual("%25".removePercentEncoding(), "%")
        XCTAssertEqual("%2d".removePercentEncoding(), "-")
        XCTAssertEqual("%2e".removePercentEncoding(), ".")
        XCTAssertEqual("%3C".removePercentEncoding(), "<")
        XCTAssertEqual("%3E".removePercentEncoding(), ">")
        XCTAssertEqual("%5C".removePercentEncoding(), "\\")
        XCTAssertEqual("%5E".removePercentEncoding(), "^")
        XCTAssertEqual("%5F".removePercentEncoding(), "_")
        XCTAssertEqual("%60".removePercentEncoding(), "`")
        XCTAssertEqual("%7B".removePercentEncoding(), "{")
        XCTAssertEqual("%7C".removePercentEncoding(), "|")
        XCTAssertEqual("%7D".removePercentEncoding(), "}")
        XCTAssertEqual("%7E".removePercentEncoding(), "~")
        XCTAssertEqual("%7e".removePercentEncoding(), "~")
    }
}

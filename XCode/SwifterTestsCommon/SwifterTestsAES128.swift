//
//  SwifterTestsAES128.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//
//

import XCTest
import Swifter

class SwifterTestsAES: XCTestCase {
    
    func testAES() {
        
        // Values from: http://csrc.nist.gov/publications/fips/fips197/fips-197.pdf ( Page 34 )

        let key = AES128.Key(
            k0: UInt8(0x2b),
            k1: UInt8(0x7e),
            k2: UInt8(0x15),
            k3: UInt8(0x16),
            k4: UInt8(0x28),
            k5: UInt8(0xae),
            k6: UInt8(0xd2),
            k7: UInt8(0xa6),
            k8: UInt8(0xab),
            k9: UInt8(0xf7),
            k10: UInt8(0x15),
            k11: UInt8(0x88),
            k12: UInt8(0x09),
            k13: UInt8(0xcf),
            k14: UInt8(0x4f),
            k15: UInt8(0x3c))
        
        let text = AES128.Block(
            s00: 0x32, s01: 0x88, s02: 0x31, s03: 0xe0,
            s10: 0x43, s11: 0x5a, s12: 0x31, s13: 0x37,
            s20: 0xf6, s21: 0x30, s22: 0x98, s23: 0x07,
            s30: 0xa8, s31: 0x8d, s32: 0xa2, s33: 0x34
        )
        
        let encrypted = AES128.encryptBlock(text, key)
        
        XCTAssert(encrypted.s00 == 0x39)
        XCTAssert(encrypted.s10 == 0x25)
        XCTAssert(encrypted.s20 == 0x84)
        XCTAssert(encrypted.s30 == 0x1d)
        
        XCTAssert(encrypted.s01 == 0x02)
        XCTAssert(encrypted.s11 == 0xdc)
        XCTAssert(encrypted.s21 == 0x09)
        XCTAssert(encrypted.s31 == 0xfb)
        
        XCTAssert(encrypted.s02 == 0xdc)
        XCTAssert(encrypted.s12 == 0x11)
        XCTAssert(encrypted.s22 == 0x85)
        XCTAssert(encrypted.s32 == 0x97)
        
        XCTAssert(encrypted.s03 == 0x19)
        XCTAssert(encrypted.s13 == 0x6a)
        XCTAssert(encrypted.s23 == 0x0b)
        XCTAssert(encrypted.s33 == 0x32)
        
    }
}

//
//  String+Hash.swift
//  Swifter
//
//  Copyright 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

extension String {
    
    public func sha1() -> String {
        
        var message = [UInt8](self.utf8)
        
        let h0 = 0x67452301
        let h1 = 0xEFCDAB89
        let h2 = 0x98BADCFE
        let h3 = 0x10325476
        let h4 = 0xC3D2E1F0
        
        // ml = message length in bits (always a multiple of the number of bits in a character).
        
        let ml = UInt64(message.count * 8)
        
        // append the bit '1' to the message e.g. by adding 0x80 if message length is a multiple of 8 bits.
        
        message.append(0x80)
        
        // append 0 ≤ k < 512 bits '0', such that the resulting message length in bits is congruent to −64 ≡ 448 (mod 512)
        
        var padBytesCount = message.count % 64
        
        while padBytesCount + 4 < 64 {
            message.append(0x00)
            padBytesCount = padBytesCount + 1
        }
        
        // append ml, in a 64-bit big-endian integer. Thus, the total length is a multiple of 512 bits.
        
        var bigEndian = ml.bigEndian
        let bytePtr = withUnsafePointer(&bigEndian) {
            UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: sizeofValue(bigEndian))
        }
        let byteArray = Array(bytePtr)
        
        message.appendContentsOf(byteArray)
        
        // Process the message in successive 512-bit chunks:

        
        return "//TODO"
    }
}
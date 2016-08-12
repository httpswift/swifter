//
//  SHA256.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif


public struct SHA256 {
    
    public static func hash(_ input: [UInt8]) -> [UInt8] {
        
        // Alghorithm from: https://en.wikipedia.org/wiki/SHA-2
        // http://csrc.nist.gov/publications/fips/fips180-4/fips-180-4.pdf
        
        var message = input
        
        var h0 = UInt32(littleEndian: 0x6a09e667)
        var h1 = UInt32(littleEndian: 0xbb67ae85)
        var h2 = UInt32(littleEndian: 0x3c6ef372)
        var h3 = UInt32(littleEndian: 0xa54ff53a)
        var h4 = UInt32(littleEndian: 0x510e527f)
        var h5 = UInt32(littleEndian: 0x9b05688c)
        var h6 = UInt32(littleEndian: 0x1f83d9ab)
        var h7 = UInt32(littleEndian: 0x5be0cd19)
        
        // ml = message length in bits (always a multiple of the number of bits in a character).
        
        let ml = UInt64(message.count * 8)
        
        // append the bit '1' to the message e.g. by adding 0x80 if message length is a multiple of 8 bits.
        
        message.append(0x80)
        
        // append 0 ≤ k < 512 bits '0', such that the resulting message length in bits is congruent to −64 ≡ 448 (mod 512)
        
        let padBytesCount = ( message.count + 8 ) % 64
        
        message.append(contentsOf: [UInt8](repeating: 0, count: 64 - padBytesCount))
        
        // append ml, in a 64-bit big-endian integer. Thus, the total length is a multiple of 512 bits.
        
        var mlBigEndian = ml.bigEndian
        withUnsafePointer(&mlBigEndian) {
            message.append(contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: 8)))
        }
        
        // Process the message in successive 512-bit chunks ( 64 bytes chunks ):
        
        for chunkStart in 0..<message.count/64 {
            var words = [UInt32](repeating: 0, count: 64)
            let chunk = message[chunkStart*64..<chunkStart*64+64]
            
            // Break chunk into sixteen 32-bit big-endian words w[i], 0 ≤ i ≤ 15
            
            for i in 0...15 {
                let value = chunk.withUnsafeBufferPointer({ UnsafePointer<UInt32>($0.baseAddress! + (i*4)).pointee})
                words[i] = value.bigEndian
            }
        
            // Extend the first 16 words into the remaining 48 words w[16..63] of the message schedule array:
            
            for i in 16..<words.count {
                let s0 = (rotateRight(words[i-15],  7)) ^ (rotateRight(words[i-15], 18)) ^ (words[i-15] >> 3 )
                let s1 = (rotateRight(words[i-2 ], 17)) ^ (rotateRight(words[i-2 ], 19)) ^ (words[i-2 ] >> 10)
                words[i] = words[i-16] &+ s0 &+ words[i-7] &+ s1
            }
            
            // Initialize hash value for this chunk:
            
            var a = h0
            var b = h1
            var c = h2
            var d = h3
            var e = h4
            var f = h5
            var g = h6
            var h = h7
            

            for i in 0...63 {
                
                let S0 = rotateRight(a, 2) ^ rotateRight(a, 13) ^ rotateRight(a, 22)
                let S1 = rotateRight(e, 6) ^ rotateRight(e, 11) ^ rotateRight(e, 25)
                
                let ch = (e & f) ^ ((~e) & g)
                let maj = (a & b) ^ (a & c) ^ (b & c)
                
                let temp1 = h &+ S1 &+ ch &+ K[i] &+ words[i]
                let temp2 = S0 &+ maj
                
                h = g
                g = f
                f = e
                e = d &+ temp1
                d = c
                c = b
                b = a
                a = temp1 &+ temp2
            }
            
            // Add this chunk's hash to result so far:
            
            h0 = ( h0 &+ a )
            h1 = ( h1 &+ b )
            h2 = ( h2 &+ c )
            h3 = ( h3 &+ d )
            h4 = ( h4 &+ e )
            h5 = ( h5 &+ f )
            h6 = ( h6 &+ g )
            h7 = ( h7 &+ h )
            
            
            
        }
        
        // Produce the final hash value (big-endian):
        
        var digest = [UInt8]()
        
        h0 = h0.bigEndian
        h1 = h1.bigEndian
        h2 = h2.bigEndian
        h3 = h3.bigEndian
        h4 = h4.bigEndian
        h5 = h5.bigEndian
        h6 = h6.bigEndian
        h7 = h7.bigEndian
        
        withUnsafePointer(&h0) {
            digest.append(contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: 4)))
        }
        withUnsafePointer(&h1) {
            digest.append(contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: 4)))
        }
        withUnsafePointer(&h2) {
            digest.append(contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: 4)))
        }
        withUnsafePointer(&h3) {
            digest.append(contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: 4)))
        }
        withUnsafePointer(&h4) {
            digest.append(contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: 4)))
        }
        withUnsafePointer(&h5) {
            digest.append(contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: 4)))
        }
        withUnsafePointer(&h6) {
            digest.append(contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: 4)))
        }
        withUnsafePointer(&h7) {
            digest.append(contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: 4)))
        }
        
        
        return digest
    }
    
    private static func rotateRight(_ v : UInt32, _ n: UInt32) -> UInt32 {
        return (v >> n) | (v << (32 - n))
    }
    
    private static func rotateLeft(_ v: UInt32, _ n: UInt32) -> UInt32 {
        return ((v << n) & 0xFFFFFFFF) | (v >> (32 - n))
    }
    
    private static var K: [UInt32] = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    ]
}

extension String {
    
    public func sha256() -> String {
        return self.sha256().hex()
    }
    
    public func sha256() -> [UInt8] {
        return SHA256.hash([UInt8](self.utf8))
    }
}

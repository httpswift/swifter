//
//  MD5.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif


public struct MD5 {
    
    // 
    // Alghorithm from: https://en.wikipedia.org/wiki/MD5
    //
    
    public static func hash(_ input: [UInt8]) -> [UInt8] {
        
        var a0 = UInt32(littleEndian: 0x67452301)
        var b0 = UInt32(littleEndian: 0xefcdab89)
        var c0 = UInt32(littleEndian: 0x98badcfe)
        var d0 = UInt32(littleEndian: 0x10325476)
        
        var message = input + [0x80] + [UInt8](repeating: 0, count: 64 - ((input.count+9) % 64))

        var originalLengthInBits = UInt64(input.count * 8).littleEndian
        
        withUnsafePointer(&originalLengthInBits) {
            message.append(contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: 8)))
        }
        
        for chunkStart in 0..<message.count/64 {
            var words = [UInt32]()
            let chunk = message[chunkStart*64..<chunkStart*64+64]
            
            for i in 0...15 {
                words.append(chunk.withUnsafeBufferPointer {
                    UnsafePointer<UInt32>($0.baseAddress! + (i*4)).pointee
                })
            }
            
            var A = a0, B = b0, C = c0, D = d0
            
            for i in 0...63 {
                var F = UInt32(0), g = UInt32(0)
                switch i {
                    case 0...15:
                        F = (B & C) | ((~B) & D)
                        g = UInt32(i)
                    case 16...31:
                        F = (D & B) | ((~D) & C)
                        g = UInt32(5*i + 1) % UInt32(16)
                    case 32...47:
                        F = B ^ C ^ D
                        g = UInt32((3*i + 5)) % UInt32(16)
                    case 48...63:
                        F = C ^ (B | (~D))
                        g = UInt32(7*i) % UInt32(16)
                    default: break
                }
                let dTemp = D
                D = C
                C = B
                B = B &+ leftrotate((A &+ F &+ K[i] &+ words[Int(g)]), s[i])
                A = dTemp
            }
            
            a0 = a0 &+ A
            b0 = b0 &+ B
            c0 = c0 &+ C
            d0 = d0 &+ D
        }
        
        var digest = [UInt8]()
        
        a0 = a0.littleEndian
        b0 = b0.littleEndian
        c0 = c0.littleEndian
        d0 = d0.littleEndian
        
        withUnsafePointer(&a0) {
            digest.append(contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: 4)))
        }
        withUnsafePointer(&b0) {
            digest.append(contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: 4)))
        }
        withUnsafePointer(&c0) {
            digest.append(contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: 4)))
        }
        withUnsafePointer(&d0) {
            digest.append(contentsOf: Array(UnsafeBufferPointer<UInt8>(start: UnsafePointer($0), count: 4)))
        }
        
        return digest
    }
    
    private static func leftrotate(_ v: UInt32, _ n: UInt32) -> UInt32 {
        return ((v << n) & 0xFFFFFFFF) | (v >> (32 - n))
    }
    
    private static var s: [UInt32] = [
        7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,  7, 12, 17, 22,
        5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,  5,  9, 14, 20,
        4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,  4, 11, 16, 23,
        6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21,  6, 10, 15, 21
    ]
    
    private static var K: [UInt32] = [
        0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
        0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
        0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
        0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
        0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
        0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
        0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
        0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
        0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
        0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
        0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
        0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
        0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
        0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
        0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
        0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
    ]
}

extension String {
    
    public func md5() -> String {
        return self.md5().hex()
    }
    
    public func md5() -> [UInt8] {
        return MD5.hash([UInt8](self.utf8))
    }
}

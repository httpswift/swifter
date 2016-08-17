//
//  HMAC.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import Foundation


public struct HMAC {
    
    //
    // HMAC: Keyed-Hashing for Message Authentication
    //
    // https://en.wikipedia.org/wiki/Hash-based_message_authentication_code
    // https://tools.ietf.org/html/rfc2104
    //
    
    public static func sha1(_ key: [UInt8], _ message: [UInt8]) -> [UInt8] {
        return generate(key, message, (blockSize: 64, { block in
            return SHA1.hash(block)
        }))
    }
    
    public static func sha1(_ key: [UInt8], _ message: [UInt8]) -> String {
        return sha1(key, message).hex()
    }
    
    public static func sha256(_ key: [UInt8], _ message: [UInt8]) -> [UInt8] {
        return generate(key, message, (blockSize: 64, { block in
            return SHA256.hash(block)
        }))
    }
    
    public static func sha256(_ key: [UInt8], _ message: [UInt8]) -> String {
        return sha256(key, message).hex()
    }
    
    public static func md5(_ key: [UInt8], _ message: [UInt8]) -> [UInt8] {
        return generate(key, message, (blockSize: 64, { block in
            return MD5.hash(block)
        }))
    }
    
    public static func md5(_ key: [UInt8], _ message: [UInt8]) -> String {
        let digest: [UInt8] = md5(key, message)
        return digest.hex()
    }
    
    public static func generate(_ key: [UInt8], _ message: [UInt8], _ setup: (blockSize: Int, hash: ([UInt8]) -> [UInt8])) -> [UInt8] {
        
        var paddedKey = key
        
        if paddedKey.count > setup.blockSize {
            paddedKey = setup.hash(paddedKey)
        } else if paddedKey.count < setup.blockSize {
            paddedKey = paddedKey + [UInt8](repeating: 0, count: setup.blockSize - paddedKey.count)
        }
        
        let oKeyPad = paddedKey.map { $0 ^ UInt8(0x5c) }
        let iKeyPad = paddedKey.map { $0 ^ UInt8(0x36) }
        
        return setup.hash(oKeyPad + setup.hash(iKeyPad + message))
    }
}

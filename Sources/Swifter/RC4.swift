//
//  RC4.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif


public struct RC4 {
    
    //
    // Rivest Cipher 4
    //
    // https://en.wikipedia.org/wiki/RC4
    //
    
    // TODO Improvements:
    //   - Use inout structs rather than copies.
    //   - Avoid key schedule every encrypt(...) call.
    
    public static func encrypt(_ data: [UInt8], _ key : [UInt8]) -> [UInt8] {
        return generate(data, key)
    }
    
    public static func decrypt(_ data: [UInt8], _ key : [UInt8]) -> [UInt8] {
        return generate(data, key)
    }
    
    private static func generate(_ data: [UInt8], _ key : [UInt8]) -> [UInt8] {
        
        var S = keySchedule(key)
        var ouput = [UInt8]()
        var i = 0, j = 0
        
        for byte in data {
            
            i = ( i + 1 ) % 256
            j = ( j + Int(S[i]) ) % 256
            
            let tmp = S[i]
            S[i] = S[j]
            S[j] = tmp
            
            let t = (Int(S[i]) + Int(S[j])) % 256
            let k = S[t]
            
            ouput.append(k ^ byte)
        }
        
        return ouput
    }
    
    private static func keySchedule(_ key: [UInt8]) -> [UInt8] {
        
        var S = [UInt8](repeating: 0, count: 256)
        
        for i in 0..<S.count {
            S[i] = UInt8(i)
        }
        
        var j : Int = 0
        
        for i in 0..<S.count {
            j = ( j + Int(S[i]) + Int(key[i % key.count]) ) % 256
            let tmp = S[i]
            S[i] = S[j]
            S[j] = tmp
        }
        
        return S
    }
    
}

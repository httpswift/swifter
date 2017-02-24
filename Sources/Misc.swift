//
//  Misc.swift
//  Swifter
//
//  Copyright © 2017 Damian Kołakowski. All rights reserved.
//

import Foundation

public extension UInt8 {
    
    public static var
        lf: UInt8 = 10,
        cr: UInt8 = 13,
        space: UInt8 = 32,
        colon: UInt8 = 58,
        ampersand: UInt8 = 38,
        lessThan: UInt8 = 60,
        greaterThan: UInt8 = 62,
        slash: UInt8 = 47,
        equal: UInt8 = 61,
        doubleQuotes: UInt8 = 34,
        openingParenthesis: UInt8 = 40,
        closingParenthesis: UInt8 = 41,
        comma: UInt8 = 44
}

public struct Process {
    
    public static var pid: Int {
        return Int(getpid())
    }
    
    public static var tid: UInt64 {
        #if os(Linux)
            return UInt64(pthread_self())
        #else
            var tid: __uint64_t = 0
            pthread_threadid_np(nil, &tid);
            return UInt64(tid)
        #endif
    }
    
    public static var error: String {
        return String(cString: UnsafePointer(strerror(errno)))
    }
}


//
//  Errno.swift
//  Swifter
//
//  Created by Damian Kolakowski on 13/07/16.
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif


public struct Errno {
    
    public static var description: String {
        return String(cString: UnsafePointer(strerror(errno))) ?? "Error: \(errno)"
    }
}

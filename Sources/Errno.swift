//
//  Errno.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

public class Errno {
    
    public class func description() -> String {
        return String(cString: UnsafePointer(strerror(errno)))
    }
}

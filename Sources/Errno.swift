//
//  Errno.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public class Errno {
    
    public class func description() -> String {
        return String(cString: UnsafePointer(strerror(errno)))
    }
}

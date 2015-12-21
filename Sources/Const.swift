//
//  Const.swift
//  Swifter
//
//  Created by Damian Kolakowski on 17/12/15.
//  Copyright © 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
#if os(Linux)
    import Glibc
    import NSLinux
#endif

struct Constants {
    
    static let VERSION      = "1.0.4"
    static let DEFAULT_PORT = in_port_t(8080)
    
    static let CR           = UInt8(13)
    static let NL           = UInt8(10)
}
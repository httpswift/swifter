//
//  HEX.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import Foundation

extension Sequence where Iterator.Element == UInt8 {
    
    public func hex() -> String {
        return self.reduce("") { $0 + String(format: "%02x", $1) }
    }
}

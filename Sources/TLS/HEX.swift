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

extension String {
    
    public func asHexArray() -> [UInt8] {
        var result = [UInt8]()
        var iterator = self.unicodeScalars.makeIterator()
        while let scalar = iterator.next(), let nextScalar = iterator.next() {
            let value = ( (hexToDecimal(scalar)) * 16 ) + (hexToDecimal(nextScalar))
            if value < UInt32(UINT8_MAX) {
                result.append(UInt8(value))
            }
        }
        return result
    }
    
    private func hexToDecimal(_ input: UnicodeScalar) -> UInt32 {
        switch input {
            case "0"..."9":
                return input.value - 48
            case "A"..."F":
                return input.value - 65 + 10
            case "a"..."f":
                return input.value - 97 + 10
            default:
                return 0
        }
    }
}

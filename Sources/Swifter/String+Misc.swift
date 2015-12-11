//
//  String+Linux.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

extension String {

    public func split(separator: Character) -> [String] {
        return self.characters.split { $0 == separator }.map(String.init)
    }
    
    public func replace(old: Character, new: Character) -> String {
        var buffer = [Character]()
        self.characters.forEach { buffer.append($0 == old ? new : $0) }
        return String(buffer)
    }
    
    public func trim() -> String {
        var scalars = self.unicodeScalars
        while let _ = unicodeScalarToUInt32Whitespace(scalars.first) { scalars.removeFirst() }
        while let _ = unicodeScalarToUInt32Whitespace(scalars.last) { scalars.removeLast() }
        return String(scalars)
    }
    
    public func removePercentEncoding() -> String {
        var scalars = self.unicodeScalars
        var buffer = [Character]()
        while let scalar = scalars.popFirst() {
            guard scalar.isASCII() else {
                buffer.append(Character(scalar))
                continue
            }
            if scalar == "%" {
                let first = scalars.popFirst()
                let secon = scalars.popFirst()
                if let first = unicodeScalarToUInt32Hex(first), secon = unicodeScalarToUInt32Hex(secon) {
                    buffer.append(Character(UnicodeScalar(first*16+secon)))
                } else {
                    if let first = first {
                        buffer.append(Character(first))
                    }
                    if let secon = secon {
                        buffer.append(Character(secon))
                    }
                }
            } else {
                buffer.append(Character(scalar))
            }
        }
        return String(buffer)
    }
    
    private func unicodeScalarToUInt32Whitespace(x: UnicodeScalar?) -> UInt32? {
        if let x = x {
            if x.value >= 9 && x.value <= 13 {
                return x.value
            }
            if x.value == 32 {
                return x.value
            }
        }
        return nil
    }
    
    private func unicodeScalarToUInt32Hex(x: UnicodeScalar?) -> UInt32? {
        if let x = x {
            if x.value >= 48 && x.value <= 57 {
                return x.value - 48
            }
            if x.value >= 97 && x.value <= 102 {
                return x.value - 97
            }
            if x.value >= 65 && x.value <= 70 {
                return x.value - 65
            }
        }
        return nil
    }
}

//
//  String+Misc.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation


extension String {

    public func split(_ separator: Character) -> [String] {
        return self.characters.split { $0 == separator }.map(String.init)
    }
    
    public func split(_ maxSplit: Int = Int.max, separator: Character) -> [String] {
        return self.characters.split(maxSplits: maxSplit, omittingEmptySubsequences: true) { $0 == separator }.map(String.init)
    }
    
    public func replace(old: Character, _ new: Character) -> String {
        var buffer = [Character]()
        self.characters.forEach { buffer.append($0 == old ? new : $0) }
        return String(buffer)
    }
    
    public func unquote() -> String {
        var scalars = self.unicodeScalars;
        if scalars.first == "\"" && scalars.last == "\"" && scalars.count >= 2 {
            scalars.removeFirst();
            scalars.removeLast();
            return String(scalars)
        }
        return self
    }
    
    public func trim() -> String {
        var scalars = self.unicodeScalars
        while let _ = scalars.first?.asWhitespace() { scalars.removeFirst() }
        while let _ = scalars.last?.asWhitespace() { scalars.removeLast() }
        return String(scalars)
    }
    
    public static func fromUInt8(_ array: [UInt8]) -> String {
        // Apple changes the definition of String(data: .... ) every release so let's stay with 'fromUInt8(...)' wrapper.
        return array.reduce("", { $0.0 + String(UnicodeScalar($0.1)) })
    }
    
}

extension UnicodeScalar {
    
    public func asWhitespace() -> UInt8? {
        if self.value >= 9 && self.value <= 13 {
            return UInt8(self.value)
        }
        if self.value == 32 {
            return UInt8(self.value)
        }
        return nil
    }
    
}

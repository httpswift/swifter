//
//  JSON.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

// TODO 
//  - Fix NSNumber extension decoding procedure.
//  - Escape key string.

public protocol JsonConvertable {
    
    func asJson(_ ident: UInt?) -> String
}

extension String: JsonConvertable {
    
    public func asJson(_ ident: UInt? = 0) -> String {
        return self.unicodeScalars.reduce("\"") { (c, s) -> String in
            switch s.value {
            case 0 : return c + "\\0"
            case 7 : return c + "\\a"
            case 8 : return c + "\\b"
            case 9 : return c + "\\t"
            case 10: return c + "\\n"
            case 11: return c + "\\v"
            case 12: return c + "\\f"
            case 13: return c + "\\r"
            case 34: return c + "\\\""
            case 39: return c + "\\'"
            case 47: return c + "\\/"
            case 92: return c + "\\\\"
            case let n where n > 127: return c + "\\u" + String(format:"%04X", n)
            default:
                return c + String(s)
            }
        } + "\""
    }
}

extension Bool: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return self ? "true" : "false"
    }
}

extension Double: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return String(self)
    }
}

extension Float: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return String(self)
    }
}

extension Int: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return String(self)
    }
}

extension UInt: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return String(self)
    }
}

extension Int8: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return String(self)
    }
}

extension UInt8: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return String(self)
    }
}

extension Int16: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return String(self)
    }
}

extension UInt16: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return String(self)
    }
}

extension Int32: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return String(self)
    }
}

extension UInt32: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return String(self)
    }
}

extension Int64: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return String(self)
    }
}

extension UInt64: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return String(self)
    }
}

extension Dictionary where Key: ExpressibleByStringLiteral, Value: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return "{" + self.map({ "\"\($0.0)\":" + $0.1.asJson(ident) }).joined(separator: ",") + "}"
    }
}

extension Collection where Iterator.Element: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return "[" + (self.map({ $0.asJson(ident) }).joined(separator: ",")) + "]"
    }
}

extension Array where Element: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return "[" + (self.map({ $0.asJson(ident) }).joined(separator: ",")) + "]"
    }
}

extension NSString: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return (self as String).asJson(ident)
    }
}

extension NSArray: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return "[" + (self.map({ ($0 as? JsonConvertable)?.asJson(ident) ?? "null" }).joined(separator: ",")) + "]"
    }
}

extension NSNumber: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        switch String(cString: objCType) {
            case "c":
                if self == kCFBooleanTrue || self == kCFBooleanFalse {
                    return self.boolValue.asJson(ident)
                }
                return self.int8Value.asJson(ident)
            case "s": return self.int16Value.asJson(ident)
            case "i": return self.int32Value.asJson(ident)
            case "q": return self.int64Value.asJson(ident)
            case "f": return self.floatValue.asJson(ident)
            case "d": return self.doubleValue.asJson(ident)
        default:
            return self.boolValue.asJson(ident)
        }
    }
}

extension NSDictionary: JsonConvertable {
    
    public func asJson(_ ident: UInt?) -> String {
        return "{" + self.map({ "\"\($0.0)\":" + (($0.1 as? JsonConvertable)?.asJson(ident) ?? "null") }).joined(separator: ",") + "}"
    }
}

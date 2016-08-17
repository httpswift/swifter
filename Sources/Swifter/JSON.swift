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

extension Dictionary {
    
    public func asJson() -> String {
        var tokens = [String]()
        for (key, value) in self {
            if let stringKey = key as? String {
                tokens.append(escapeString(stringKey) + ":" + toJsonValue(value))
            }
        }
        return "{" + tokens.joined(separator: ",") + "}"
    }
}

extension Array {
    
    public func asJson() -> String {
        return "[" + self.map({ toJsonValue($0) }).joined(separator: ",") + "]"
    }
}

private func escapeString(_ string: String) -> String {
    return string.unicodeScalars.reduce("\"") { (c, s) -> String in
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

private func toJsonValue(_ value: Any?) -> String {
    if let value = value {
        switch value {
        case let int as Int8:   return String(int)
        case let int as UInt8:  return String(int)
        case let int as Int16:  return String(int)
        case let int as UInt16: return String(int)
        case let int as Int32: return String(int)
        case let int as UInt32: return String(int)
        case let int as Int64: return String(int)
        case let int as UInt64: return String(int)
        case let int as Int: return String(int)
        case let int as UInt: return String(int)
        case let int as Float: return String(int)
        case let int as Double: return String(int)
        case let bool as Bool: return bool ? "true" : "false"
        case let dict as Dictionary<String, Any>: return dict.asJson()
        case let dict as Dictionary<String, Any?>: return dict.asJson()
        case let array as Array<Any>: return array.asJson()
        case let array as Array<Any?>: return array.asJson()
        case let string as String: return escapeString(string)
        default:
            return "null"
        }
    }
    return "null"
}

//
//  BigNum.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public struct BigNum: Equatable, Comparable, CustomStringConvertible {
    
    //
    // Big Integer
    //
    // TODO/Improvments
    //  - add init(...) for string literal
    //  - add powmod operation
    
    internal var digits = [UInt8]()
    internal var signum = 0
    
    internal init(_ digits: [UInt8], _ signum: Int) {
        self.digits.append(contentsOf: digits)
        self.signum = signum
    }
    
    internal init(_ digits: ArraySlice<UInt8>, _ signum: Int) {
        self.digits.append(contentsOf: digits)
        self.signum = signum
    }
    
    public init(_ text: String) {
        
        if text.unicodeScalars.isEmpty {
            self.signum = 0
            self.digits = [0]
            return
        }
        
        if (text.unicodeScalars.count == 1) && (text.unicodeScalars[text.unicodeScalars.startIndex].value == 48) {
            self.signum = 0
            self.digits = [0]
            return
        }
        
        self.signum = 1
        
        for c in text.unicodeScalars.reversed() {
            switch c.value {
            case 48...57:
                self.digits.append(UInt8(c.value-48))
            case 45:
                self.signum = -1
            default: break
            }
        }
    }
    
    public var description: String {
        return (self.signum < 0 ? "-" : "") + self.digits.reversed().reduce("") { $0 + String($1) }
    }
}

public func == (_ left: BigNum, right: BigNum) -> Bool {
    return (left.digits == right.digits) && (left.signum == right.signum)
}

public func != (_ left: BigNum, right: BigNum) -> Bool {
    return !(left.digits == right.digits)
}

public func + (_ left: BigNum, _ right: BigNum) -> BigNum {
    
    if right.signum == 0 {
        return left
    }
    
    if left.signum == 0 {
        return right
    }
    
    if (left.signum < 0) && (right.signum < 0) {
        return BigNum((BigNum(left.digits, 1) + BigNum(right.digits, 1)).digits, -1)
    }
    
    if (left.signum > 0) && (right.signum < 0) {
        return (left - BigNum(right.digits, 1))
    }
    
    if (left.signum < 0) && (right.signum > 0) {
        return BigNum((right - BigNum(left.digits, 1)).digits, -1)
    }
    
    var result = [UInt8]()
    var carry: UInt8 = 0
    for i in 0..<max(left.digits.count, right.digits.count) {
        let sum = (((i < left.digits.count) ? left.digits[i] : 0) +
            ((i < right.digits.count) ? right.digits[i] : 0)) + carry
        if sum >= 10 {
            carry = sum / 10
            result.append(sum - 10)
        } else {
            carry = 0
            result.append(sum)
        }
    }
    if carry != 0 {
        result.append(carry)
    }
    
    while let last = result.last, last == 0 { result.removeLast() }
    
    return result.isEmpty ? BigNum(result, 0) : BigNum(result, 1)
}

public func - (_ left: BigNum, _ right: BigNum) -> BigNum {
    
    if right.signum == 0 {
        return left
    }
    
    if left.signum == 0 {
        return BigNum(right.digits, right.signum * (-1))
    }
    
    if left == right {
        return BigNum([0], 0)
    }
    
    if right > left {
        return BigNum((right - left).digits, -1)
    }
    
    if (left.signum < 0) && (right.signum > 0) {
        return BigNum((BigNum(left.digits, 1) + right).digits, -1)
    }
    
    var result = [UInt8]()
    var carry: Int = 0
    for i in 0..<max(right.digits.count, left.digits.count) {
        let sub = (Int((i < left.digits.count) ? left.digits[i] : 0) -
            Int((i < right.digits.count) ? right.digits[i] : 0)) + carry
        if sub < 0 {
            carry = -1
            result.append(UInt8(10+sub))
        } else {
            carry = 0
            result.append(UInt8(sub))
        }
    }
    
    while let last = result.last, last == 0 { result.removeLast() }
    
    return result.isEmpty ? BigNum(result, 0) : BigNum(result, 1)
}

public func * (_ left: BigNum, _ right: BigNum) -> BigNum {
    if (left.signum == 0) || (right.signum == 0) {
        return BigNum([], 0)
    }
    var mulResults = Array<[UInt8]>()
    for i in 0..<left.digits.count {
        var row = [UInt8](repeating: 0, count: i)
        var carry: UInt8 = 0
        for j in 0..<right.digits.count {
            let mul = (left.digits[i] * right.digits[j]) + carry
            if mul > 9 {
                carry = mul / 10
                row.append(mul % 10)
            } else {
                carry = 0
                row.append(mul)
            }
        }
        if carry != 0 {
            row.append(carry % 10)
            if carry > 9 { row.append(carry / 10) }
        }
        mulResults.append(row)
    }
    var sum = mulResults.reduce(BigNum([0], 1)) { $0.0 + BigNum($0.1, 1) }
    sum.signum = left.signum * right.signum
    return sum
}

public func / (_ left: BigNum, _ right: BigNum) -> (quotient: BigNum, reminder: BigNum) {
    
    if left < right {
        return (BigNum([0], 0), left)
    }
    
    if left.digits == right.digits {
        return (BigNum([1], left.signum * right.signum), BigNum([0], 0))
    }
    
    var shiftIndex = left.digits.count - right.digits.count
    var tmp = BigNum(left.digits[shiftIndex..<left.digits.count], 1)
    
    while tmp < right {
        shiftIndex = shiftIndex - 1
        tmp = BigNum(left.digits[shiftIndex..<left.digits.count], 1)
    }
    
    var quotient = [UInt8]()
    var rest = BigNum([0], 0)
    
    while shiftIndex >= 0 {
        var i: UInt8 = 1
        while (right * BigNum([i], 1)) < tmp {
            i = i + 1
        }
        quotient.append(i-1)
        rest = tmp - (right * BigNum([i-1], 1))
        shiftIndex = shiftIndex - 1
        if shiftIndex < 0 {
            break
        }
        tmp = BigNum([left.digits[shiftIndex]] + rest.digits, 1)
    }
    
    return (BigNum(quotient.reversed(), left.signum * right.signum), rest)
}

public func % (_ left: BigNum, _ right: BigNum) -> BigNum {
    return (left / right).reminder
}

public func > (_ left: BigNum, _ right: BigNum) -> Bool {
    if left.signum != right.signum {
        return left.signum > right.signum
    }
    if left.digits.count != right.digits.count {
        if left.signum < 0 {
            return left.digits.count < right.digits.count
        } else {
            return left.digits.count > right.digits.count
        }
    }
    for i in (0..<left.digits.count).reversed() {
        if left.digits[i] != right.digits[i] {
            if left.signum < 0 {
                return left.digits[i] < right.digits[i]
            } else {
                return left.digits[i] > right.digits[i]
            }
        }
    }
    return false
}

public func < (_ left: BigNum, _ right: BigNum) -> Bool {
    if left.signum != right.signum {
        return left.signum < right.signum
    }
    if right.digits.count != left.digits.count {
        if left.signum < 0 {
            return left.digits.count > right.digits.count
        } else {
            return left.digits.count < right.digits.count
        }
    }
    for i in (0..<left.digits.count).reversed() {
        if left.digits[i] != right.digits[i] {
            if left.signum < 0 {
                return right.digits[i] < left.digits[i]
            } else {
                return right.digits[i] > left.digits[i]
            }
        }
    }
    return false
}

public func >= (_ left: BigNum, _ right: BigNum) -> Bool {
    return (left == right) || (left > right)
}

public func <= (_ left: BigNum, _ right: BigNum) -> Bool {
    return (left == right) || (left < right)
}

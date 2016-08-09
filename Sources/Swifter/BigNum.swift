//
//  BigNum.swift
//  Swifter
//
//  Created by Damian Kolakowski on 08/08/16.
//

import Foundation

public struct BigNum {
    
    // 
    // Big Integer
    //
    // TODO/Improvments
    //  - add init(...) for string literal
    //  - switch to 'long division'
    //  - fix '+' and '-' operators for negative numbers
    
    internal var digits = [UInt8]()
    internal var signum = 0
    
    internal init(_ digits: [UInt8]) {
        self.digits.append(contentsOf: digits)
        self.signum = digits.isEmpty ? 0 : 1
    }
    
    public init(_ text: String) {
        self.signum = text.unicodeScalars.isEmpty ? 0 : 1
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
}

infix operator == { }
public func == (_ left: BigNum, right: BigNum) -> Bool {
    return (left.digits == right.digits) && (left.signum == right.signum)
}

infix operator + { }
public func + (_ left: BigNum, _ right: BigNum) -> BigNum {
    var result = [UInt8]()
    var carry: UInt8 = 0
    for i in 0..<max(left.digits.count, right.digits.count) {
        let leftDigit = (i < left.digits.count) ? left.digits[i] : 0
        let rightDigit = (i < right.digits.count) ? right.digits[i] : 0
        let sum = (leftDigit + rightDigit) + carry
        if sum > 9 {
            carry = 1
            result.append(sum - 10)
        } else {
            carry = 0
            result.append(sum)
        }
    }
    if carry != 0 {
        result.append(carry)
    }
    return BigNum(result)
}

infix operator - { }
public func - (_ left: BigNum, _ right: BigNum) -> BigNum {
    var result = [UInt8]()
    var carry: Int = 0
    for i in 0..<max(left.digits.count, right.digits.count) {
        let leftDigit = (i < left.digits.count) ? left.digits[i] : 0
        let rightDigit = (i < right.digits.count) ? right.digits[i] : 0
        let diff = (Int(leftDigit) - Int(rightDigit)) + carry
        if diff < 0 {
            carry = -1
            result.append(UInt8(10+diff))
        } else {
            carry = 0
            result.append(UInt8(diff))
        }
    }
    while let last = result.last, last == 0 { result.removeLast() }
    return BigNum(result)
}

infix operator * { }
public func * (_ left: BigNum, _ right: BigNum) -> BigNum {
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
    var sum = mulResults.reduce(BigNum([0])) { $0.partialResult + BigNum($0.1) }
    sum.signum = left.signum * right.signum
    return sum
}

infix operator / { }
public func / (_ left: BigNum, _ right: BigNum) -> BigNum {
    if left < right {
        return BigNum([0])
    }
    var quotient = BigNum([0])
    var remainder = left
    
    while remainder >= right {
        quotient = quotient + BigNum([1])
        remainder = remainder - right
    }
    
    quotient.signum = left.signum * right.signum
    
    return quotient
}

infix operator % { }
public func % (_ left: BigNum, _ right: BigNum) -> BigNum {
    if left < right {
        return left
    }
    var quotient = BigNum([0])
    var remainder = left
    
    while remainder >= right {
        quotient = quotient + BigNum([1])
        remainder = remainder - right
    }
    return remainder
}

infix operator > { }
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
    for i in 0..<left.digits.count {
        if left.digits[i] == right.digits[i] {
            continue
        }
        if left.signum < 0 {
            if left.digits[i] < right.digits[i] {
                return true
            }
        } else {
            if left.digits[i] > right.digits[i] {
                return true
            }
        }
    }
    return false
}

infix operator < { }
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
    for i in 0..<left.digits.count {
        if left.digits[i] == right.digits[i] {
            continue
        }
        if left.signum < 0 {
            if right.digits[i] < left.digits[i] {
                return true
            }
        } else {
            if right.digits[i] > left.digits[i] {
                return true
            }
        }
    }
    return false
}

infix operator >= { }
public func >= (_ left: BigNum, _ right: BigNum) -> Bool {
    return (left == right) || (left > right)
}

infix operator <= { }
public func <= (_ left: BigNum, _ right: BigNum) -> Bool {
    return (left == right) || (left < right)
}

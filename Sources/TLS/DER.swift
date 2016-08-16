//
//  DER.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public struct DER {
    
    //
    // Distinguished Encoding Rules (DER)
    //
    // https://en.wikipedia.org/wiki/X.690
    //
    
    public enum DecodeError: Error { case invalidData }
    
    public enum DERClass: UInt8 { case universal = 0, application = 1, context = 2, priv = 3 }
    
    public static func decode(_ input: [UInt8]) throws -> DEROObject {
        var iterator = input[0..<input.count].makeIterator()
        return try parseObject(&iterator)
    }
    
    public struct DEROObject {
        public let clazz: DERClass
        public let primitive: Bool
        public let tag: UInt32
        public let data: [UInt8]
    }
    
    private static func parseObject(_ generator: inout IndexingIterator<ArraySlice<UInt8>>) throws -> DEROObject {
        
        guard let first = generator.next() else { throw DecodeError.invalidData }
        
        let clazz = try parseClass(first)
        let primitive = try parsePrimitive(first)
        let tag = try parseTag(first, &generator)
        let data = try parseContent(&generator)
        
        return DEROObject(clazz: clazz, primitive: primitive, tag: tag, data: data)
    }
    
    private static func parsePrimitive(_ first: UInt8) throws -> Bool {
        return (first & 0x20) == 0
    }
    
    private static func parseClass(_ first: UInt8) throws -> DERClass {
        if let cls = DERClass(rawValue: (first & 0xC0) >> 6) {
            return cls
        }
        throw DecodeError.invalidData
    }
    
    private static func parseTag(_ first: UInt8, _ generator: inout IndexingIterator<ArraySlice<UInt8>>) throws -> UInt32 {
        
        switch first & 0x1F {
        
        case let short where short < 0x1F:
            
            return UInt32(short)
            
        case let long where long == 0x1F:
            // Arbitrary allow only for UInt32 as max TAG value.
            var buffer = [UInt8](repeating: 0, count: 4)
            for i in 0..<buffer.count {
                guard let b = generator.next() else { throw DecodeError.invalidData }
                buffer[i] = (b & 0x7F)
                if b & 0x80 != 0 { break }
            }
            // Validate if the last byte has leading 0 bit. We read 4 tag bytes but there could be more.
            guard buffer[3] & 0x80 != 0 else {
                throw DecodeError.invalidData
            }
            
            return buffer.withUnsafeBufferPointer { UnsafePointer<UInt32>($0.baseAddress!).pointee.littleEndian }
            
        default:
            
            throw DecodeError.invalidData
        }
    }
    
    private static func parseContent(_ generator: inout IndexingIterator<ArraySlice<UInt8>>) throws -> [UInt8] {
        
        guard let length = generator.next() else { throw DecodeError.invalidData }
        
        switch length {
            
            case 0..<0x80:
                
                var content = [UInt8]()
                for _ in 0..<length {
                    guard let b = generator.next() else { throw DecodeError.invalidData }
                    content.append(b)
                }
                return content
            
            case 0x80:

                throw DecodeError.invalidData // DER - Length encoding must use the definite form
            
            default:
        
                let numberOfDigits = Int(length & 0x7F)
                
                if numberOfDigits > 4 { /* Arbitrary allow only for UInt32 max content size. */ throw DecodeError.invalidData }
                
                var buffer = [UInt8]()
                
                for _ in 0..<numberOfDigits {
                    guard let b = generator.next() else { throw DecodeError.invalidData }
                    buffer.append(b)
                }
                
                buffer = buffer.reversed() + /* padding */ [UInt8](repeating: 0, count: 4 - numberOfDigits)
                let length = buffer.withUnsafeBufferPointer { UnsafePointer<UInt32>($0.baseAddress!).pointee.littleEndian }
            
                var content = [UInt8]()
                for _ in 0..<length {
                    guard let b = generator.next() else { throw DecodeError.invalidData }
                    content.append(b)
                }
                return content
        }
    }
  
}

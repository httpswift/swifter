//
//  AES128.swift
//  Swifter
//
//  Copyright 2014-2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif


public struct AES128 {
    
    //
    // Advanced Encryption Standard
    //
    // http://csrc.nist.gov/publications/fips/fips197/fips-197.pdf
    //
    
    // TODO Improvements:
    //   - Use inout structs rather than copies.
    //   - Introduce a util method for printing the content of Array<UInt8> as hex string.
    //   - Avoid key expansion every encryptBlock(...) call.
    //   - Add support for init with literals.

    public struct Key: CustomStringConvertible {
        
        public init(k0: UInt8, k1: UInt8, k2: UInt8, k3: UInt8, k4: UInt8, k5: UInt8, k6: UInt8, k7: UInt8, k8: UInt8, k9: UInt8, k10: UInt8, k11: UInt8, k12: UInt8, k13: UInt8, k14: UInt8, k15: UInt8) {
            self.k0 = k0
            self.k1 = k1
            self.k2 = k2
            self.k3 = k3
            self.k4 = k4
            self.k5 = k5
            self.k6 = k6
            self.k7 = k7
            self.k8 = k8
            self.k9 = k9
            self.k10 = k10
            self.k11 = k11
            self.k12 = k12
            self.k13 = k13
            self.k14 = k14
            self.k15 = k15
        }
        
        public var k0, k1, k2 , k3 : UInt8
        public var k4, k5, k6 , k7 : UInt8
        public var k8, k9, k10, k11 : UInt8
        public var k12, k13, k14, k15 : UInt8
        
        public var description: String {
            return "[" + [k0, k1, k2, k3, k4, k5, k6, k7, k8, k8, k10, k11, k12, k13, k14, k15].map({ String(format: "%02x", $0) }).joined(separator: ",") + "]"
        }
    }
    
    public struct Block: CustomStringConvertible {
        
        public init(s00: UInt8, s01: UInt8, s02: UInt8, s03: UInt8, s10: UInt8, s11: UInt8, s12: UInt8, s13: UInt8, s20: UInt8, s21: UInt8, s22: UInt8, s23: UInt8, s30: UInt8, s31: UInt8, s32: UInt8, s33: UInt8) {
            self.s00 = s00
            self.s01 = s01
            self.s02 = s02
            self.s03 = s03
            self.s10 = s10
            self.s11 = s11
            self.s12 = s12
            self.s13 = s13
            self.s20 = s20
            self.s21 = s21
            self.s22 = s22
            self.s23 = s23
            self.s30 = s30
            self.s31 = s31
            self.s32 = s32
            self.s33 = s33
        }
        
        public var s00, s01, s02, s03 : UInt8
        public var s10, s11, s12, s13 : UInt8
        public var s20, s21, s22, s23 : UInt8
        public var s30, s31, s32, s33 : UInt8
        
        public var description: String {
            return
                "[" + [self.s00, self.s01, self.s02, self.s03].map({ String(format: "%02x", $0) }).joined(separator: ",") + "]\n" +
                "[" + [self.s10, self.s11, self.s12, self.s13].map({ String(format: "%02x", $0) }).joined(separator: ",") + "]\n" +
                "[" + [self.s20, self.s21, self.s22, self.s23].map({ String(format: "%02x", $0) }).joined(separator: ",") + "]\n" +
                "[" + [self.s30, self.s31, self.s32, self.s33].map({ String(format: "%02x", $0) }).joined(separator: ",") + "]"
        }
    }
    
    public static func encryptBlock(_ block: Block, _ key: Key) -> Block {
        
        let roundKeys = keyExpansion(key)
        
        var tmpBlock = block
        
        tmpBlock = addRoundKey(tmpBlock, roundKeys[0], roundKeys[1], roundKeys[2], roundKeys[3])
        
        for i in 1...10 {
            
            tmpBlock = subBytes(tmpBlock)
            tmpBlock = shiftRows(tmpBlock)
            
            if i != 10 {
                tmpBlock = mixColumns(tmpBlock)
            }
            
            let index = i*4
            tmpBlock = addRoundKey(tmpBlock, roundKeys[index], roundKeys[index+1], roundKeys[index+2], roundKeys[index+3])
        }
        
        return tmpBlock
    }
    
    private static func addRoundKey(_ block: Block, _ kw0: KeyWord, _ kw1: KeyWord, _ kw2: KeyWord, _ kw3: KeyWord) -> Block {
        return Block(
            s00: block.s00 ^ kw0.w0, s01: block.s01 ^ kw1.w0, s02: block.s02 ^ kw2.w0, s03: block.s03 ^ kw3.w0,
            s10: block.s10 ^ kw0.w1, s11: block.s11 ^ kw1.w1, s12: block.s12 ^ kw2.w1, s13: block.s13 ^ kw3.w1,
            s20: block.s20 ^ kw0.w2, s21: block.s21 ^ kw1.w2, s22: block.s22 ^ kw2.w2, s23: block.s23 ^ kw3.w2,
            s30: block.s30 ^ kw0.w3, s31: block.s31 ^ kw1.w3, s32: block.s32 ^ kw2.w3, s33: block.s33 ^ kw3.w3
        )
    }
    
    public static func subBytes(_ state: Block) -> Block {
        return Block(
            s00: sboxLookup(state.s00), s01: sboxLookup(state.s01), s02: sboxLookup(state.s02), s03: sboxLookup(state.s03),
            s10: sboxLookup(state.s10), s11: sboxLookup(state.s11), s12: sboxLookup(state.s12), s13: sboxLookup(state.s13),
            s20: sboxLookup(state.s20), s21: sboxLookup(state.s21), s22: sboxLookup(state.s22), s23: sboxLookup(state.s23),
            s30: sboxLookup(state.s30), s31: sboxLookup(state.s31), s32: sboxLookup(state.s32), s33: sboxLookup(state.s33)
        )
    }
    
    public static func shiftRows(_ state: Block) -> Block {
        return Block(
            s00: state.s00, s01: state.s01, s02: state.s02, s03: state.s03,
            s10: state.s11, s11: state.s12, s12: state.s13, s13: state.s10,
            s20: state.s22, s21: state.s23, s22: state.s20, s23: state.s21,
            s30: state.s33, s31: state.s30, s32: state.s31, s33: state.s32
        )
    }
    
    private static func m2(_ value: UInt8) -> UInt8 {
        let shifted = value << 1
        return value & 0x80 > 0 ? ( shifted ^ 0x1B ) : shifted
    }
    
    private static func m3(_ value: UInt8) -> UInt8 {
        return value ^ m2(value)
    }
    
    private static func mixColumns(_ state: Block) -> Block {
        
        return Block(
            
            s00: m2(state.s00) ^ m3(state.s10) ^ state.s20 ^ state.s30,
            s01: m2(state.s01) ^ m3(state.s11) ^ state.s21 ^ state.s31,
            s02: m2(state.s02) ^ m3(state.s12) ^ state.s22 ^ state.s32,
            s03: m2(state.s03) ^ m3(state.s13) ^ state.s23 ^ state.s33,
            
            s10: state.s00 ^ m2(state.s10) ^ m3(state.s20) ^ state.s30,
            s11: state.s01 ^ m2(state.s11) ^ m3(state.s21) ^ state.s31,
            s12: state.s02 ^ m2(state.s12) ^ m3(state.s22) ^ state.s32,
            s13: state.s03 ^ m2(state.s13) ^ m3(state.s23) ^ state.s33,
            
            s20: state.s00 ^ state.s10 ^ m2(state.s20) ^ m3(state.s30),
            s21: state.s01 ^ state.s11 ^ m2(state.s21) ^ m3(state.s31),
            s22: state.s02 ^ state.s12 ^ m2(state.s22) ^ m3(state.s32),
            s23: state.s03 ^ state.s13 ^ m2(state.s23) ^ m3(state.s33),
            
            s30: m3(state.s00) ^ state.s10 ^ state.s20 ^ m2(state.s30),
            s31: m3(state.s01) ^ state.s11 ^ state.s21 ^ m2(state.s31),
            s32: m3(state.s02) ^ state.s12 ^ state.s22 ^ m2(state.s32),
            s33: m3(state.s03) ^ state.s13 ^ state.s23 ^ m2(state.s33)
        )
    }
    
    public struct KeyWord: CustomStringConvertible {
        
        public var w0, w1, w2, w3: UInt8
        
        public var description: String {
            return "[" + [w0, w1, w2, w3].map({ String(format: "%02x", $0) }).joined(separator: ",") + "]"
        }
    }
    
    private static func rotWord(_ word: KeyWord) -> KeyWord {
        return KeyWord(w0: word.w1, w1: word.w2, w2: word.w3, w3: word.w0)
    }
    
    private static func subWord(_ word: KeyWord) -> KeyWord {
        return KeyWord(w0: sboxLookup(word.w0), w1: sboxLookup(word.w1), w2: sboxLookup(word.w2), w3: sboxLookup(word.w3))
    }
    
    private static func addWord(_ word1: KeyWord, _ word2: KeyWord) -> KeyWord {
        return KeyWord(w0: word1.w0 ^ word2.w0, w1: word1.w1 ^ word2.w1, w2: word1.w2 ^ word2.w2, w3: word1.w3 ^ word2.w3)
    }
    
    private static func keyExpansion(_ key: Key) -> [KeyWord] {
        
        var words = [KeyWord]()
        
        words.append(KeyWord(w0: key.k0,  w1: key.k1,  w2: key.k2,  w3: key.k3))
        words.append(KeyWord(w0: key.k4,  w1: key.k5,  w2: key.k6,  w3: key.k7))
        words.append(KeyWord(w0: key.k8,  w1: key.k9,  w2: key.k10, w3: key.k11))
        words.append(KeyWord(w0: key.k12, w1: key.k13, w2: key.k14, w3: key.k15))
        
        var rcon = [KeyWord]()
        
        rcon.append(KeyWord(w0: 0x01, w1: 0, w2: 0, w3: 0))
        rcon.append(KeyWord(w0: 0x02, w1: 0, w2: 0, w3: 0))
        rcon.append(KeyWord(w0: 0x04, w1: 0, w2: 0, w3: 0))
        rcon.append(KeyWord(w0: 0x08, w1: 0, w2: 0, w3: 0))
        rcon.append(KeyWord(w0: 0x10, w1: 0, w2: 0, w3: 0))
        rcon.append(KeyWord(w0: 0x20, w1: 0, w2: 0, w3: 0))
        rcon.append(KeyWord(w0: 0x40, w1: 0, w2: 0, w3: 0))
        rcon.append(KeyWord(w0: 0x80, w1: 0, w2: 0, w3: 0))
        rcon.append(KeyWord(w0: 0x1b, w1: 0, w2: 0, w3: 0))
        rcon.append(KeyWord(w0: 0x36, w1: 0, w2: 0, w3: 0))
        
        for i in 4..<44 {
            var temp = words[i-1]
            if i % 4 == 0 {
                temp = addWord(subWord(rotWord(temp)), rcon[(i-1)/4])
            }
            words.append(addWord(words[i-4], temp))
        }
        
        return words
    }
    
    private static var sbox: [UInt8] = [
        0x63, 0x7C, 0x77, 0x7B, 0xF2, 0x6B, 0x6F, 0xC5, 0x30, 0x01, 0x67, 0x2B, 0xFE, 0xD7, 0xAB, 0x76,
        0xCA, 0x82, 0xC9, 0x7D, 0xFA, 0x59, 0x47, 0xF0, 0xAD, 0xD4, 0xA2, 0xAF, 0x9C, 0xA4, 0x72, 0xC0,
        0xB7, 0xFD, 0x93, 0x26, 0x36, 0x3F, 0xF7, 0xCC, 0x34, 0xA5, 0xE5, 0xF1, 0x71, 0xD8, 0x31, 0x15,
        0x04, 0xC7, 0x23, 0xC3, 0x18, 0x96, 0x05, 0x9A, 0x07, 0x12, 0x80, 0xE2, 0xEB, 0x27, 0xB2, 0x75,
        0x09, 0x83, 0x2C, 0x1A, 0x1B, 0x6E, 0x5A, 0xA0, 0x52, 0x3B, 0xD6, 0xB3, 0x29, 0xE3, 0x2F, 0x84,
        0x53, 0xD1, 0x00, 0xED, 0x20, 0xFC, 0xB1, 0x5B, 0x6A, 0xCB, 0xBE, 0x39, 0x4A, 0x4C, 0x58, 0xCF,
        0xD0, 0xEF, 0xAA, 0xFB, 0x43, 0x4D, 0x33, 0x85, 0x45, 0xF9, 0x02, 0x7F, 0x50, 0x3C, 0x9F, 0xA8,
        0x51, 0xA3, 0x40, 0x8F, 0x92, 0x9D, 0x38, 0xF5, 0xBC, 0xB6, 0xDA, 0x21, 0x10, 0xFF, 0xF3, 0xD2,
        0xCD, 0x0C, 0x13, 0xEC, 0x5F, 0x97, 0x44, 0x17, 0xC4, 0xA7, 0x7E, 0x3D, 0x64, 0x5D, 0x19, 0x73,
        0x60, 0x81, 0x4F, 0xDC, 0x22, 0x2A, 0x90, 0x88, 0x46, 0xEE, 0xB8, 0x14, 0xDE, 0x5E, 0x0B, 0xDB,
        0xE0, 0x32, 0x3A, 0x0A, 0x49, 0x06, 0x24, 0x5C, 0xC2, 0xD3, 0xAC, 0x62, 0x91, 0x95, 0xE4, 0x79,
        0xE7, 0xC8, 0x37, 0x6D, 0x8D, 0xD5, 0x4E, 0xA9, 0x6C, 0x56, 0xF4, 0xEA, 0x65, 0x7A, 0xAE, 0x08,
        0xBA, 0x78, 0x25, 0x2E, 0x1C, 0xA6, 0xB4, 0xC6, 0xE8, 0xDD, 0x74, 0x1F, 0x4B, 0xBD, 0x8B, 0x8A,
        0x70, 0x3E, 0xB5, 0x66, 0x48, 0x03, 0xF6, 0x0E, 0x61, 0x35, 0x57, 0xB9, 0x86, 0xC1, 0x1D, 0x9E,
        0xE1, 0xF8, 0x98, 0x11, 0x69, 0xD9, 0x8E, 0x94, 0x9B, 0x1E, 0x87, 0xE9, 0xCE, 0x55, 0x28, 0xDF,
        0x8C, 0xA1, 0x89, 0x0D, 0xBF, 0xE6, 0x42, 0x68, 0x41, 0x99, 0x2D, 0x0F, 0xB0, 0x54, 0xBB, 0x16
    ]
    
    private static func sboxLookup(_ value: UInt8) -> UInt8 {
        let rowIndex = value >> 4
        let colIndex = value & 0x0F
        return sbox[Int(rowIndex*16+colIndex)]
    }
}


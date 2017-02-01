//
//  String+BASE64.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import Foundation


extension String {
    
    private static let CODES = [UInt8]("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=".utf8)
    
    public static func toBase64(_ data: [UInt8]) -> String? {
        
        // Based on: https://en.wikipedia.org/wiki/Base64#Sample_Implementation_in_Java
        
        var result = [UInt8]()
        var tmp: UInt8
        for index in stride(from: 0, to: data.count, by: 3) {
            let byte = data[index]
            tmp = (byte & 0xFC) >> 2;
            result.append(CODES[Int(tmp)])
            tmp = (byte & 0x03) << 4;
            if index + 1 < data.count {
                tmp |= (data[index + 1] & 0xF0) >> 4;
                result.append(CODES[Int(tmp)]);
                tmp = (data[index + 1] & 0x0F) << 2;
                if (index + 2 < data.count)  {
                    tmp |= (data[index + 2] & 0xC0) >> 6;
                    result.append(CODES[Int(tmp)]);
                    tmp = data[index + 2] & 0x3F;
                    result.append(CODES[Int(tmp)]);
                } else  {
                    result.append(CODES[Int(tmp)]);
                    result.append(contentsOf: [UInt8]("=".utf8));
                }
            } else {
                result.append(CODES[Int(tmp)]);
                result.append(contentsOf: [UInt8]("==".utf8));
            }
        }
        return String(bytes: result, encoding: .utf8)
    }
}

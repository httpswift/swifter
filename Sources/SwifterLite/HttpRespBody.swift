//
//  HttpRespBody.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public enum HttpResponseBody {
    
    case json(Any)
    case text(String)
    case data(Data, contentType: String? = nil)
    case bytes([UInt8], contentType: String? = nil)

    func content() -> (Int, ((HttpResponseBodyWriter) throws -> Void)?) {
        do {
            switch self {
            case .json(let object):
                guard
                    JSONSerialization.isValidJSONObject(object)
                else {
                    throw SerializationError.invalidObject
                }
                let data = try JSONSerialization.data(withJSONObject: object)
                return (data.count, {
                    try $0.write(data: data)
                })
            case .text(let body):
                let data = [UInt8](body.utf8)
                return (data.count, {
                    try $0.write(bytes: data)
                })
            case .data(let data, _):
                return (data.count, {
                    try $0.write(data: data)
                })
            case .bytes(let bytes, _):
                return (bytes.count, {
                    try $0.write(bytes: bytes)
                })
            }
        } catch {
            let data = [UInt8]("Serialization error: \(error)".utf8)
            return (data.count, {
                try $0.write(bytes: data)
            })
        }
    }
}

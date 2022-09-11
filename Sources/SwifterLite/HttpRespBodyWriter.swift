//
//  HttpRespBodyWriter.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public enum SerializationError: Error {
    case invalidObject
    case notSupported
}

public protocol HttpResponseBodyWriter {
    func write(data : Data) throws
    func write(bytes: [UInt8]) throws
}

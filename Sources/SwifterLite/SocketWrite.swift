//
//  SocketWrite.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

extension Socket {
    public func writeUTF8(_ string: String) throws {
        try writeBuffer([UInt8](string.utf8), length: (string.utf8).count)
    }
    
    public func writeUInt8(_ data: [UInt8]) throws {
        try writeBuffer([UInt8](data), length: data.count)
    }

    public func writeData(_ data: Data) throws {
        try writeBuffer([UInt8](data), length: data.count)
    }

    private func writeBuffer(_ pointer: UnsafeRawPointer, length: Int) throws {
        var sent = 0
        while sent < length {
            let result = write(self.socketFileDescriptor, pointer + sent, Int(length - sent))

            if result <= 0 {
                throw SocketError.writeFailed(ErrNumString.description())
            }
            sent += result
        }
    }
}

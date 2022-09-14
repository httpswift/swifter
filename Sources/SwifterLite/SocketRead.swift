//
//  SocketRead.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//
//  SwifterLite
//  Copyright (c) 2022 Todd Bruss. All rights reserved.
//

import Foundation

extension Socket {
 
    /// - Returns: A single byte
    /// - Throws: SocketError.recvFailed if unable to read from the socket
    open func read() throws -> UInt8 {
        var byte: UInt8 = 0
        
        if Darwin.read(self.socketFileDescriptor as Int32, &byte, 1) > 0 {
            return byte
        }
        
        throw SocketError.recvFailed(ErrNumString.description())
    }
    
    public func readLine() throws -> String {
        var string: String = ""
        var index: UInt8 = 0
        
        repeat {
            index = try self.read()
            if index > Socket.CR { string.append(Character(UnicodeScalar(index))) }
        } while index != Socket.NL
        
        return string
    }
    
    /// - Parameter length: The maximum bytes to read
    /// - Returns: A buffer containing the bytes read
    /// - Throws: SocketError.recvFailed if unable to read bytes from the socket
    open func read(length: Int) throws -> [UInt8] {
         try [UInt8](unsafeUninitializedCapacity: length) { buffer, bytesRead in
            bytesRead = try read(into: &buffer, length: length)
        }
    }
    
    /// - Parameter into: The buffer to read into (must be at least length bytes in size)
    /// - Parameter length: The maximum bytes to read
    /// - Returns: The number of bytes read
    /// - Throws: SocketError.recvFailed if unable to read bytes from the socket
    func read(into buffer: inout UnsafeMutableBufferPointer<UInt8>, length: Int) throws -> Int {
        var offset = 0
        
        while offset < length {
            // Compute next read length in bytes. The bytes read is never more than kBufferLength at once.
            let readLength = offset + Socket.kBufferLength < length ? Socket.kBufferLength : length - offset
            
            if
                let baseAddress = buffer.baseAddress,
                case let bytesRead = Darwin.read(self.socketFileDescriptor as Int32, baseAddress + offset, readLength) {
                offset += bytesRead
            } else {
                throw SocketError.recvFailed(ErrNumString.description())
            }
        }
        
        return offset
    }
}

//
//  Socket+TLS.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public enum TLSError: Error {
    case UnknownTLSRecordType(String)
    case UnknownHandshakeType(String)
    case InvalidData(String)
}

public protocol HasBigEndian {
    var bigEndian: Self { get }
}

public func nextBytes(_ socket: Socket, _ n: Int) throws -> [UInt8] {
    var result = [UInt8]()
    for _ in 0..<n {
        result.append(try socket.read())
    }
    return result
}

public func nextGeneric2<T: HasBigEndian>(_ socket: Socket) throws -> T {
    return try nextBytes(socket, MemoryLayout<T>.size).withUnsafeBufferPointer() { UnsafePointer<T>(OpaquePointer($0.baseAddress!)).pointee }.bigEndian
}

public func nextUInt16(_ socket: Socket) throws -> UInt16 {
    return try nextBytes(socket, MemoryLayout<UInt16>.size).withUnsafeBufferPointer() { UnsafePointer<UInt16>(OpaquePointer($0.baseAddress!)).pointee }.bigEndian
}

public struct DataIterator {
    
    private var iterator: IndexingIterator<ArraySlice<UInt8>>
    
    public init(_ slice: ArraySlice<UInt8>) {
        self.iterator = slice.makeIterator()
    }
    
    public mutating func next(_ n: Int) -> [UInt8]? {
        var result = [UInt8]()
        for _ in 0..<n {
            guard let nextByte = self.iterator.next() else {
                return nil
            }
            result.append(nextByte)
        }
        return result
    }
    
    public mutating func nextByte() -> UInt8? {
        return self.iterator.next()
    }
    
    public mutating func nextUInt16() -> UInt16? {
        return next(MemoryLayout<UInt16>.size)?.withUnsafeBufferPointer() { UnsafePointer<UInt16>(OpaquePointer($0.baseAddress!)).pointee }.bigEndian
    }
}

extension Socket {
    
    public func acceptTLSClientSocket() throws -> Socket {
        let socket = try self.acceptClientSocket()
        let record = try readRecord(socket)
        switch record.type {
            case .HANDSHAKE:
                let handshake = try readHandshake(socket)
                switch handshake.type {
                case Handshake.Typo.CLIENT_HELLO:
                    let _ = try readClientHello(handshake.message)
                default:
                    print("default")
                }
                print("handshake")
            case .CHANGE_CIPHER_SPEC:
                print("TODO")
            case .ALERT:
                print("TODO")
            case .APPLICATION_DATA:
                print("TODO")
        }
        return socket
    }
    
    public struct Record {
        
        public enum Typo: UInt8 { case CHANGE_CIPHER_SPEC = 20, ALERT = 21, HANDSHAKE = 22, APPLICATION_DATA = 23 }
        
        public var type: Typo
        public var version: UInt16
        public var length: UInt16
    }
    
    public func readRecord(_ socket: Socket) throws -> Record {

        let type = try socket.read()
        
        guard let validType = Record.Typo(rawValue: type) else {
            throw TLSError.UnknownTLSRecordType("Unknown record type: \(type)")
        }
        
        let version = try nextUInt16(socket)
        let lengthh = try nextUInt16(socket)
        
        return Record(type: validType, version: version, length: lengthh)
    }
    
    public struct Handshake {
        
        public enum Typo: UInt8 {
            case HELLO_REQUEST = 0, CLIENT_HELLO = 1, SERVER_HELLO = 2, FINISHED = 20
            case CERTIFICATE = 11, SERVER_KEY_EXCHANGE = 12, CERTIFICATE_REQUEST = 13
            case SERVER_DONE = 14, CERTIFICATE_VERIFY = 15, CLIENT_KEY_EXCHANGE = 16
        }
        
        public var type = Typo.HELLO_REQUEST
        public var message = [UInt8]()
    }
    
    public func readHandshake(_ socket: Socket) throws -> Handshake {
        
        let type = try socket.read()
        
        guard let validType = Handshake.Typo(rawValue: type) else {
            throw TLSError.UnknownHandshakeType("Unknown record type: \(type)")
        }
        
        var handshake = Handshake()
        
        handshake.type = validType
        
        let length2 = try socket.read()
        let length1 = try socket.read()
        let length0 = try socket.read()
        
        let length = [length0, length1, length2, 0].withUnsafeBufferPointer() { UnsafePointer<UInt32>(OpaquePointer($0.baseAddress!)).pointee }.littleEndian
        
        while UInt32(handshake.message.count) < length { handshake.message.append(try socket.read()) }
        
        return handshake
    }
    
    public struct ClientHello {
        
        public var version: UInt16 = 0
        public var random = [UInt8]()
        public var sessionId = [UInt8]()
        
        public var cipherSuites = [UInt16]()
        public var compressionMethods = [UInt8]()
        
        public var extensions = [(id: UInt16, data: [UInt8])]()
    }
    
    
    public func readClientHello(_ data: [UInt8]) throws -> ClientHello {

        var iterator = DataIterator(data[0..<data.count])
        
        guard let version = iterator.nextUInt16() else { throw TLSError.InvalidData("No version field.") }
        
        guard let random = iterator.next(32) else { throw TLSError.InvalidData("No random field.") }
        
        guard let sessionIdLen = iterator.nextByte() else { throw TLSError.InvalidData("No Session Id Length field.") }
        
        guard let sessionId = iterator.next(Int(sessionIdLen)) else { throw TLSError.InvalidData("No Session Id field.") }
        
        guard let cipherSuitesCount = iterator.nextUInt16(), cipherSuitesCount % 2 == 0 else {
            throw TLSError.InvalidData("No Cipher Suites Count field.")
        }
        
        var cipherSuites = [UInt16]()
        
        for _ in 0..<cipherSuitesCount/2 {
            guard let cipherSuiteId = iterator.nextUInt16() else { throw TLSError.InvalidData("No Cipher Suite Id field.") }
            cipherSuites.append(cipherSuiteId)
        }
        guard let compressionMethodsCount = iterator.nextByte() else {
            throw TLSError.InvalidData("No first byte of the version field in Hello message \(data)")
        }
        guard let compressionMethods = iterator.next(Int(compressionMethodsCount)) else {
            throw TLSError.InvalidData("No Compression Method field.")
        }
        
        guard let extensionsLength = iterator.nextUInt16() else { throw TLSError.InvalidData("No Extension Length field.") }
        guard let extensionsData = iterator.next(Int(extensionsLength)) else { throw TLSError.InvalidData("No Extension Data field.") }
        
        var extensionDataIterator = DataIterator(extensionsData[0..<extensionsData.count])
        
        var extensions = [(id: UInt16, data: [UInt8])]()
        
        while true {
            guard let extensionId = extensionDataIterator.nextUInt16() else {
                break
            }
            guard let extensionDataLength = extensionDataIterator.nextUInt16() else {
                throw TLSError.InvalidData("No first byte of the version field in Hello message \(data)")
            }
            guard let extensionData = extensionDataIterator.next(Int(extensionDataLength)) else {
                throw TLSError.InvalidData("No first byte of the version field in Hello message \(data)")
            }
            extensions.append((id: extensionId, data: extensionData))
        }
        
        return ClientHello(version: version, random: random, sessionId: sessionId,
                           cipherSuites: cipherSuites, compressionMethods: compressionMethods, extensions: extensions)
    }
}


//
//  HttpRouter.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

#if !os(Linux)
private func ensureNoErr(_ status: OSStatus) throws {
    guard status == noErr else {
        throw Errno.sslError(from: status)
    }
}

public enum TLS {
    /// Imports .p12 certificate file constructing structure to be used in TLS session.
    ///
    /// See [SecPKCS12Import](https://developer.apple.com/documentation/security/1396915-secpkcs12import).
    /// Apple docs contain a misleading information that it does not import items to Keychain even though
    /// it does.
    ///
    /// - Parameter data: .p12 certificate file content
    /// - Parameter password: password used when importing certificate
    public static func loadP12Certificate(_ data: Data, _ password: String) throws -> CFArray {
        let options = [kSecImportExportPassphrase as String: password]
        var items: CFArray?
        try ensureNoErr(SecPKCS12Import(data as CFData, options as NSDictionary, &items))
        guard
            let dictionary = (items as? [[String: Any]])?.first,
            let chain = dictionary[kSecImportItemCertChain as String] as? [SecCertificate]
        else {
            throw SocketError.tlsSessionFailed("Could not retrieve p12 data from given certificate")
        }
        // must be force casted, will be fixed in swift 5 https://bugs.swift.org/browse/SR-7015
        let secIdentity = dictionary[kSecImportItemIdentity as String] as! SecIdentity
        let chainWithoutIdentity = chain.dropFirst()
        let certs = [secIdentity] + chainWithoutIdentity.map { $0 as Any }
        return certs as CFArray
    }
}

open class TlsSession {

    private let context: SSLContext
    private var fdPtr = UnsafeMutablePointer<Int32>.allocate(capacity: 1)

    init(fd: Int32, certificate: CFArray) throws {
        guard let newContext = SSLCreateContext(nil, .serverSide, .streamType) else {
            throw SocketError.tlsSessionFailed("Could not create new SSL context")
        }
        context = newContext
        fdPtr.pointee = fd
        try ensureNoErr(SSLSetIOFuncs(context, sslRead, sslWrite))
        try ensureNoErr(SSLSetConnection(context, fdPtr))
        try ensureNoErr(SSLSetCertificate(context, certificate))
    }

    open func close() {
        SSLClose(context)
        fdPtr.deallocate()
    }

    open func handshake() throws {
        var status: OSStatus = -1
        repeat {
            status = SSLHandshake(context)
        } while status == errSSLWouldBlock
        try ensureNoErr(status)
    }

    /// Write up to `length` bytes to TLS session from a buffer `pointer` points to.
    ///
    /// - Returns: The number of bytes written
    /// - Throws: SocketError.tlsSessionFailed if unable to write to the session
    open func writeBuffer(_ pointer: UnsafeRawPointer, length: Int) throws -> Int {
        var written = 0
        try ensureNoErr(SSLWrite(context, pointer, length, &written))
        return written
    }

    /// Read a single byte off the TLS session.
    ///
    /// - Throws: SocketError.tlsSessionFailed if unable to read from the session
    open func readByte(_ byte: UnsafeMutablePointer<UInt8>) throws {
        _ = try read(into: byte, length: 1)
    }

    /// Read up to `length` bytes from TLS session into an existing buffer
    ///
    /// - Parameter into: The buffer to read into (must be at least length bytes in size)
    /// - Returns: The number of bytes read
    /// - Throws: SocketError.tlsSessionFailed if unable to read from the session
    open func read(into buffer: UnsafeMutablePointer<UInt8>, length: Int) throws -> Int {
        var received = 0
        try ensureNoErr(SSLRead(context, buffer, length, &received))
        return received
    }
}

private func sslWrite(connection: SSLConnectionRef, data: UnsafeRawPointer, dataLength: UnsafeMutablePointer<Int>) -> OSStatus {
    let fd = connection.assumingMemoryBound(to: Int32.self).pointee
    let bytesToWrite = dataLength.pointee

    let written = Darwin.write(fd, data, bytesToWrite)

    dataLength.pointee = written
    if written > 0 {
        return written < bytesToWrite ? errSSLWouldBlock : noErr
    }
    if written == 0 {
        return errSSLClosedGraceful
    }

    dataLength.pointee = 0
    return errno == EAGAIN ? errSSLWouldBlock : errSecIO
}

private func sslRead(connection: SSLConnectionRef, data: UnsafeMutableRawPointer, dataLength: UnsafeMutablePointer<Int>) -> OSStatus {
    let fd = connection.assumingMemoryBound(to: Int32.self).pointee
    let bytesToRead = dataLength.pointee
    let read = recv(fd, data, bytesToRead, 0)

    dataLength.pointee = read
    if read > 0 {
        return read < bytesToRead ? errSSLWouldBlock : noErr
    }

    if read == 0 {
        return errSSLClosedGraceful
    }

    dataLength.pointee = 0
    switch errno {
    case ENOENT:
        return errSSLClosedGraceful
    case EAGAIN:
        return errSSLWouldBlock
    case ECONNRESET:
        return errSSLClosedAbort
    default:
        return errSecIO
    }
}
#endif

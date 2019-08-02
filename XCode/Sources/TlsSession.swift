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
    public static func loadP12Certificate(_ _data: Data, _ password: String) throws -> CFArray {
        let data = _data as NSData
        let options = [kSecImportExportPassphrase: password]
        var items: CFArray!
        try ensureNoErr(SecPKCS12Import(data, options as NSDictionary, &items))
        let dictionary = (items! as [AnyObject])[0]
        let secIdentity = dictionary[kSecImportItemIdentity] as! SecIdentity
        let chain = dictionary[kSecImportItemCertChain] as! [SecCertificate]
        let certs = [secIdentity] + chain.dropFirst().map { $0 as Any }
        return certs as CFArray
    }
}

open class TlsSession {

    private let context: SSLContext
    private var fdPtr = UnsafeMutablePointer<Int32>.allocate(capacity: 1)

    init(fd: Int32, certificate: CFArray) throws {
        context = SSLCreateContext(nil, .serverSide, .streamType)!
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

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
#endif

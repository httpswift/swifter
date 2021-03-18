//
//  Errno.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public class Errno {

    public class func description() -> String {
        // https://forums.developer.apple.com/thread/113919
        return String(cString: strerror(errno))
    }

    #if !os(Linux)
    public class func sslError(from status: OSStatus) -> Error {
        guard let msg = getMessage(from: status) else {
            return SocketError.tlsSessionFailed("<\(status): message is not provided>")
        }
        return SocketError.tlsSessionFailed(msg)
    }

    private class func getMessage(from status: OSStatus) -> String? {
        if #available(iOS 11.3, tvOS 11.3, *) {
            guard let msg = SecCopyErrorMessageString(status, nil) else {
                return nil
            }
            return msg as String
        } else {
            return "SSL error (\(status))"
        }
    }
    #endif
}

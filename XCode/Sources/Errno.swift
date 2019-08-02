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
        guard let msg = SecCopyErrorMessageString(status, nil) else {
            return SocketError.tlsSessionFailed("<\(status): message is not provided>")
        }
        return SocketError.tlsSessionFailed(msg as NSString as String)
    }
    #endif
}

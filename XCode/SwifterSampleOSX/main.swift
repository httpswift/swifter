//
//  main.swift
//  SwifterOSX
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
import Swifter

/// For demo purposes certificate is expected to be at location
/// ~/.swifter/localhost.p12
///
/// the easiest way to create certificate for localhost is using `mkcert` tool
private func certificateData() -> Data? {
    guard let homePath = ProcessInfo.processInfo.environment["HOME"] else {
        return nil
    }
    guard let homeUrl = URL(string: homePath) else {
        return nil
    }
    let certPath = homeUrl
        .appendingPathComponent(".swifter", isDirectory: true)
        .appendingPathComponent("localhost.p12", isDirectory: false)
    return FileManager.default.contents(atPath: certPath.absoluteString)
}

do {
    let server = demoServer(try String.File.currentWorkingDirectory())
    server["/testAfterBaseRoute"] = { request in
        return .ok(.htmlBody("ok !"))
    }

    if #available(OSXApplicationExtension 10.10, *) {
        if let certData = certificateData() {
            server.sslCertificate = try TLS.loadP12Certificate(certData, "changeit")
            print("SSL certificate loaded")
        }
        try server.start(9080, forceIPv4: true)
    } else {
        // Fallback on earlier versions
    }

    print("Server has started ( port = \(try server.port()) ). Try to connect now...")

    RunLoop.main.run()

} catch {
    print("Server start error: \(error)")
}

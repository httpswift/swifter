//
//  PingServer.swift
//  Swifter
//
//  Created by Brian Gerstle on 8/20/16.
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif
@testable import Swifter

// Server
extension HttpServer {
    class func pingServer() -> HttpServer {
        let server = HttpServer()
        server.GET["/ping"] = { request in
            return HttpResponse.ok(.text("pong!"))
        }
        return server
    }
}

let defaultLocalhost = URL(string: "http://localhost:8080")!

// Client
extension URLSession {
    func pingTask(
        hostURL: URL = defaultLocalhost,
        completionHandler handler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        return self.dataTask(with: hostURL.appendingPathComponent("/ping"), completionHandler: handler)
    }

    func retryPing(
        hostURL: URL = defaultLocalhost,
        timeout: Double = 2.0
    ) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        self.signalIfPongReceived(semaphore, hostURL: hostURL)
        let timeoutDate = NSDate().addingTimeInterval(timeout)
        var timedOut = false
        while semaphore.wait(timeout: DispatchTime.now()) != DispatchTimeoutResult.timedOut {
            if NSDate().laterDate(timeoutDate as Date) != timeoutDate as Date {
                timedOut = true
                break
            }

            #if swift(>=4.2)
            let mode = RunLoop.Mode.common
            #else
            let mode = RunLoopMode.commonModes
            #endif

            _ = RunLoop.current.run(
                mode: mode,
                before: NSDate.distantFuture
            )
        }

        return timedOut
    }

    func signalIfPongReceived(_ semaphore: DispatchSemaphore, hostURL: URL) {
        pingTask(hostURL: hostURL) { _, response, _ in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                semaphore.signal()
            } else {
                self.signalIfPongReceived(semaphore, hostURL: hostURL)
            }
        }.resume()
    }
}

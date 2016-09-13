//
//  PingServer.swift
//  Swifter
//
//  Created by Brian Gerstle on 8/20/16.
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import Foundation
import Swifter

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

let defaultLocalhost = URL(string:"http://localhost:8080")!

// Client
extension URLSession {
    func pingTask(
        _ hostURL: URL = defaultLocalhost,
        completionHandler handler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) -> URLSessionDataTask {
        return self.dataTask(with: hostURL.appendingPathComponent("/ping"), completionHandler: handler)
    }
    
    func retryPing(
        _ hostURL: URL = defaultLocalhost,
        timeout: Double = 2.0
    ) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        self.signalIfPongReceived(semaphore, hostURL: hostURL)
        let timeoutDate = Date().addingTimeInterval(timeout)
        var timedOut = false
        while semaphore.wait(timeout: DispatchTime.now()) != DispatchTimeoutResult.success {
            if (Date() as NSDate).laterDate(timeoutDate) != timeoutDate {
                timedOut = true
                break
            }
            RunLoop.current.run(
                mode: RunLoopMode.commonModes,
                before: Date.distantFuture
            )
        }
        return timedOut
    }
    
    func signalIfPongReceived(_ semaphore: DispatchSemaphore, hostURL: URL) {
        pingTask(hostURL) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse , httpResponse.statusCode == 200 {
                semaphore.signal()
            } else {
                self.signalIfPongReceived(semaphore, hostURL: hostURL)
            }
        }.resume()
    }
}

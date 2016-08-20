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
            return HttpResponse.OK(.Text("pong!"))
        }
        return server
    }
}

let defaultLocalhost = NSURL(string:"http://localhost:8080")!

// Client
extension NSURLSession {
    func pingTask(
        hostURL: NSURL = defaultLocalhost,
        completionHandler handler: (NSData?, NSURLResponse?, NSError?) -> Void
    ) -> NSURLSessionDataTask {
        return self.dataTaskWithURL(hostURL.URLByAppendingPathComponent("/ping"), completionHandler: handler)
    }
    
    func retryPing(
        hostURL: NSURL = defaultLocalhost,
        timeout: Double = 2.0
    ) -> Bool {
        let semaphore = dispatch_semaphore_create(0)
        self.signalIfPongReceived(semaphore, hostURL: hostURL)
        let timeoutDate = NSDate().dateByAddingTimeInterval(timeout)
        var timedOut = false
        while dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW) != 0 {
            if NSDate().laterDate(timeoutDate) != timeoutDate {
                timedOut = true
                break
            }
            NSRunLoop.currentRunLoop().runMode(
                NSRunLoopCommonModes,
                beforeDate: NSDate.distantFuture()
            )
        }
        return timedOut
    }
    
    func signalIfPongReceived(semaphore: dispatch_semaphore_t, hostURL: NSURL) {
        pingTask(hostURL) { data, response, error in
            if let httpResponse = response as? NSHTTPURLResponse where httpResponse.statusCode == 200 {
                dispatch_semaphore_signal(semaphore)
            } else {
                self.signalIfPongReceived(semaphore, hostURL: hostURL)
            }
        }.resume()
    }
}

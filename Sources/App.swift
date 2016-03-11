//
//  App.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public class App {
    
    private let server = HttpServer()
    
    public init() { }
    
    public func run(port: in_port_t = 9080) throws -> Void {
        Process.watchSignals { signal in
            switch signal {
            case SIGTERM, SIGINT, SIGSTOP:
                self.server.stop()
                exit(EXIT_SUCCESS)
            case SIGINFO:
                print(self.server.routes.joinWithSeparator("\n"))
            case SIGHUP:
                print("//TODO - Reload config.")
            default:
                print("signal")
            }
        }
        print("Starting Swifter (\(HttpServer.VERSION)) at port \(port) with PID \(Process.PID)...")
        try self.server.start(port)
        print("Server started. Waiting for requests....")
        NSRunLoop.mainRunLoop().run()
    }
}
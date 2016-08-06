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
    
    @available(OSX 10.10, *)
    public func run(_ port: in_port_t = 9080, _ databasePath: String) throws -> Void {
        
        // Open database connection.
        
        DatabaseReflection.sharedDatabase = try SQLite.open(databasePath)
        
        defer {
            DatabaseReflection.sharedDatabase?.close()
        }
        
        // Watch process signals.
        
        Process.watchSignals { switch $0 {
            case SIGTERM, SIGINT:
                self.server.stop()
                DatabaseReflection.sharedDatabase?.close()
                exit(EXIT_SUCCESS)
            case SIGHUP:
                print("//TODO - Reload config.")
            default:
                print("Unknown signal received: \(signal).")
            }
        }
        
        // Add simple logging.
        
        self.server.middleware.append({ r in
            print("\(r.method) - \(r.path)")
            return nil
        })
        
        // Boot the server.
        
        print("Starting Swifter (\(HttpServer.VERSION)) at port \(try server.port()) with PID \(Process.tid)...")
        
        try self.server.start(port)
        
        print("Server started. Waiting for requests....")
        
        #if os(Linux)
    	    while true { }
        #else
    	    RunLoop.current.run()
        #endif
    }
}

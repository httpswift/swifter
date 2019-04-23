//
//  IOSafetyTests.swift
//  Swifter
//
//  Created by Brian Gerstle on 8/20/16.
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest
@testable import Swifter

class IOSafetyTests: XCTestCase {
    var server: HttpServer!
    var urlSession: URLSession!

    override func setUp() {
        super.setUp()
        server = HttpServer.pingServer()
        urlSession = URLSession(configuration: .default)
    }
    
    override func tearDown() {
        if server.operating {
            server.stop()
        }
        
        urlSession = nil
        server = nil
        
        super.tearDown()
    }

    func testStopWithActiveConnections() {
        (0...100).forEach { cpt in
            server = HttpServer.pingServer()
            do {
                try server.start()
                XCTAssertFalse(urlSession.retryPing())
                (0...100).forEach { _ in
                    DispatchQueue.global(qos: DispatchQoS.default.qosClass).sync {
                        urlSession.pingTask { _, _, _ in }.resume()
                    }
                }
                server.stop()
            } catch let error {
                XCTFail("\(cpt): \(error)")
            }
        }
    }
}

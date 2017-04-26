//
//  IOSafetyTests.swift
//  Swifter
//
//  Created by Brian Gerstle on 8/20/16.
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest

class IOSafetyTests: XCTestCase {
    var server: HttpServer!

    override func setUp() {
        super.setUp()
        server = HttpServer.pingServer()
    }
    
    override func tearDown() {
        if server.operating {
            server.stop()
        }
        super.tearDown()
    }

    func testStopWithActiveConnections() {
        (0...100).forEach { cpt in
            server = HttpServer.pingServer()
            do {
                try server.start()
                XCTAssertFalse(URLSession.shared.retryPing())
                (0...100).forEach { _ in
                    DispatchQueue.global(qos: DispatchQoS.default.qosClass).sync {
                        URLSession.shared.pingTask { _, _, _ in }.resume()
                    }
                }
                server.stop()
            } catch let e {
                XCTFail("\(cpt): \(e)")
            }
        }
    }
}

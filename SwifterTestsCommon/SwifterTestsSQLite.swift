//
//  SwifterTests.swift
//  SwifterTests
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest
import Swifter

class SwifterTestsSQLite: XCTestCase {
    

    func testSQLite() {
        
        print(try? File.currentWorkingDirectory())
        
        guard let databsePath = try? File.currentWorkingDirectory() + "/" + "test_\(Int64(NSDate().timeIntervalSince1970*1000)).db" else {
            XCTAssert(false, "Could not find a path for a database file.")
            return
        }
    
        do {
            let database = try SQLite.open(databsePath)
            XCTAssert(true, "Opening the database should not throw any exceptions.")
            try database.close()
        } catch {
            XCTAssert(false, "Opening the database should not throw any exceptions.")
        }
        
        do {
            let database = try SQLite.open(databsePath)
            try database.exec("CREATE TABLE swifter_tests (title TEXT, description TEXT);")
            try database.exec("INSERT INTO swifter_tests VALUES (\"Test1\", \"Test1 Description\");")
            try database.exec("INSERT INTO swifter_tests VALUES (\"Test2\", \"Test2 Description\");")
            try database.close()
        } catch {
            XCTAssert(false, "Database manipulation should not throw any exceptions: \(error).")
        }
        
        do {
            let database = try SQLite.open(databsePath)
            
            var counter = 0
            for row in try database.enumerate("SELECT * FROM swifter_tests;") {
                counter = counter + 1
            }
            XCTAssert(counter == 2, "Database should have two rows.")
            
            counter = 0
            try database.exec("SELECT * FROM swifter_tests;") { content in
                counter = counter + 1
            }
            XCTAssert(counter == 2, "Database should have two rows.")
            
            try database.close()
        } catch {
            XCTAssert(false, "Database manipulation should not throw any exceptions.")
        }

    }
}

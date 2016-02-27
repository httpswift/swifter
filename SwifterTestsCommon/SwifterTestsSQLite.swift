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
        
        let databseFileName = "test_\(Int64(NSDate().timeIntervalSince1970*1000)).db"
    
        do {
            let database = try SQLite.open(try File.currentWorkingDirectory() + "/" + databseFileName)
            XCTAssert(true, "Opening the database should not throw any exceptions.")
            try database.close()
        } catch {
            XCTAssert(false, "Opening the database should not throw any exceptions.")
        }
        
        do {
            let database = try SQLite.open(try File.currentWorkingDirectory() + "/" + databseFileName)
            try database.exec("CREATE TABLE swifter_tests (title TEXT, description TEXT);")
            try database.exec("INSERT INTO swifter_tests VALUES (\"Test1\", \"Test1 Description\");")
            try database.exec("INSERT INTO swifter_tests VALUES (\"Test2\", \"Test2 Description\");")
            try database.close()
        } catch {
            XCTAssert(false, "Database manipulation should not throw any exceptions: \(error).")
        }
        
        do {
            let database = try SQLite.open(try File.currentWorkingDirectory() + "/" + databseFileName)
            var counter = 0
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

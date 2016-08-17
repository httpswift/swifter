//
//  SwifterTestsBigNum.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest

class SwifterTestsBigNum: XCTestCase {
    
    func testAdd() {
        
        XCTAssertEqual((BigNum("0") + BigNum("0")).description, "0")
        XCTAssertEqual((BigNum("1") + BigNum("1")).description, "2")
        
        for i in 0...1000 {
            XCTAssertEqual((BigNum("\(i)") + BigNum("\(2*i)")).description, "\(3*i)")
        }
        
        XCTAssertEqual((BigNum("1") + BigNum("-1")).description, "0")
        XCTAssertEqual((BigNum("-123") + BigNum("-100")).description, "-223")
        
        XCTAssertEqual((BigNum("1212409125082591823512599999923413499") +
            BigNum("14028715021850212323919319")).description,
                       "1212409125096620538534450212247332818")
    }

}

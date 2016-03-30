//
//  SwifterTestsReflection.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import XCTest
import Swifter

class SwifterTestsReflection: XCTestCase {
    
    class BlogPost: DatabaseReflection {
        
        var message: String?
        var author: String?
    }
    
    func testSchemeAndValuesForReflection() {
        
        let blogPostInstance = BlogPost()
        blogPostInstance.author = "Me"

        let (_, fields) = blogPostInstance.schemeWithValuesMethod1()
        XCTAssertEqual((fields["author"] as? String)?.utf8.count, 2)
    }
}

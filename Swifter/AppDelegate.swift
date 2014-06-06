//
//  AppDelegate.swift
//  TestSwift
//
//  Created by Damian Kolakowski on 05/06/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let server: HttpServer = HttpServer()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        
        server["/"] = { () -> (CInt, String) in
            return (200, "<html><body>Hello Swift</body></html>")
        }
        
        server["/hello"] = { () -> (CInt, String) in
            return (200, "<html><body>Hello !</body></html>")
        }
        
        server["/demo"] = { () -> (CInt, String) in
            return (200, "<html><body><center><h2>Hello Swift</h2>" +
                "<img src=\"https://devimages.apple.com.edgekey.net/swift/images/swift-hero_2x.png\"/><br>" +
                            "<h4>\(UIDevice().name), \(UIDevice().systemVersion)</h4></center></body></html>")
        }
        
        let (result, error) = server.start(8080)
        
        return true
    }
}


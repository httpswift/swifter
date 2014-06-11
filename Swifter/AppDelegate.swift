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
        
        server["/"] = { () -> (Int, String) in
            return (HttpServer.Statuses.OK, "<html><body>Hello Swift</body></html>")
        }
        
        server["/hello"] = { () -> (Int, String) in
            return (HttpServer.Statuses.OK, "<html><body>Hello !</body></html>")
        }
        
        server["/long"] = { () -> (Int, String) in
            var longResponse = ""
            for k in 0..1000 {
                longResponse += "(\(k)),->"
            }
            return (HttpServer.Statuses.OK, longResponse)
        }
        
        server["/demo"] = { () -> (Int, String) in
            return (HttpServer.Statuses.OK, "<html><body><center><h2>Hello Swift</h2>" +
                "<img src=\"https://devimages.apple.com.edgekey.net/swift/images/swift-hero_2x.png\"/><br>" +
                            "<h4>\(UIDevice().name), \(UIDevice().systemVersion)</h4></center><iframe src=\"/demo2\"></iframe><iframe src=\"/hello\"></iframe></body></html>")
        }
        
        let (result, error) = server.start(8080)
        
        return true
    }
}


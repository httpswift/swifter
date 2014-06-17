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
        
        server["/"] = {
            return .OK("<html><body>Hello Swift</body></html>")
        }
        server["/redirect"] = {
            return .MovedPermanently("http://www.google.com")
        }
        server["/long"] = {
            var longResponse = ""
            for k in 0..1000 {
                longResponse += "(\(k)),->"
            }
            return .OK(longResponse)
        }
        server["/routes"] = {
            var listPage = "<html><body>Available services:<br><ul>"
            for item in self.server.routes() {
                listPage += "<li><a href=\"\(item)\">\(item)</a></li>"
            }
            listPage += "</ul></body></html>"
            return .OK(listPage)
        }
        server["/demo"] = {
            let demoPage =
                "<html><body><center><h2>Hello Swift</h2>" +
                "<img src=\"https://devimages.apple.com.edgekey.net/swift/images/swift-hero_2x.png\"/><br>" +
                "<h4>\(UIDevice().name), \(UIDevice().systemVersion)</h4></center>" +
                "<iframe src=\"/routes\"></iframe><iframe src=\"/hello\"></iframe></body></html>"
            return .OK(demoPage)
        }
        
        var error: NSError?
        if !server.start(error: &error) {
            NSLog("Server start error: \(error)")
        }
        
        return true
    }
}


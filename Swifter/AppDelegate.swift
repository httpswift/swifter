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
        
        server["/test"] = { (method, headers) in
            var headersInfo = ""
            for (name, value) in headers {
                headersInfo += "\(name) : \(value)<br>"
            }
            let response = "<html><body>Method: \(method)<br>\(headersInfo)</body></html>"
            return .OK(.RAW(response))
        }
        server["/json"] = { (method, headers) in
            return .OK(.JSON(["posts" : [[ "id" : 1, "message" : "hello world"],[ "id" : 2, "message" : "sample message"]], "new_updates" : false]))
        }
        server["/redirect"] = { (method, headers) in
            return .MovedPermanently("http://www.google.com")
        }
        server["/long"] = { (method, headers) in
            var longResponse = ""
            for k in 0..<1000 { longResponse += "(\(k)),->" }
            return .OK(.RAW(longResponse))
        }
        server["/"] = { (method, headers) in
            var listPage = "<html><body>Available services:<br><ul>"
            for item in self.server.routes() {
                listPage += "<li><a href=\"\(item)\">\(item)</a></li>"
            }
            listPage += "</ul></body></html>"
            return .OK(.RAW(listPage))
        }
        server["/demo"] = { (method, headers) in
            let demoPage =
                "<html><body><center><h2>Hello Swift</h2>" +
                "<img src=\"https://devimages.apple.com.edgekey.net/swift/images/swift-hero_2x.png\"/><br>" +
                "<h4>\(UIDevice().name), \(UIDevice().systemVersion)</h4></center></body></html>"
            return .OK(.RAW(demoPage))
        }
        var error: NSError?
        if !server.start(error: &error) {
            println("Server start error: \(error)")
        }
        return true
    }
}


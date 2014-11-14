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
    let server = demoServer()
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        if let resDir = NSBundle.mainBundle().resourcePath {
            server["/resources/(.+)"] = HttpHandlers.directory(resDir)
        }
        var error: NSError?
        if !server.start(error: &error) {
            println("Server start error: \(error)")
        }
        return true
    }
}


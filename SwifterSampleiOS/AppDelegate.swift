//
//  AppDelegate.swift
//  TestSwift
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation
import UIKit
import SwifteriOS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var server: HttpServer?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        return true
    }
}
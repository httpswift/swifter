//
//  ViewController.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import UIKit
import Swifter

class ViewController: UIViewController {
    
    private var server: HttpServer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let server = demoServer(NSBundle.mainBundle().resourcePath)
        do {
            try server.start()
        } catch {
            print("Server start error: \(error)")
        }
        self.server = server
    }
    
    @IBAction func likedThis(sender: UIButton) {
        self.server?.stop()
        self.server = nil
    }
}

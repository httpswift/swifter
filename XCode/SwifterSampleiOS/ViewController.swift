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
        do {
            let server = demoServer(Bundle.main.resourcePath!)
            try server.start(9080)
            self.server = server
        } catch {
            print("Server start error: \(error)")
        }
    }
    
    @IBAction func likedThis(sender: UIButton) {
        self.server?.stop()
        self.server = nil
    }
}

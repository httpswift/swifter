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
            let port: in_port_t  = 9080
            let server = demoServer(Bundle.main.resourcePath!)
            try server.start(port)
            print("Starting server at port \(port) 🚀.")
            self.server = server
        } catch {
            print("Server start error: \(error)")
        }
    }

    @IBAction func likedThis(_ sender: UIButton) {
        self.server?.stop()
        self.server = nil
    }
}

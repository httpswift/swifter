//
//  ViewController.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import UIKit
import Swifter

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.global(qos: .background).async {
            do {
                let server = try demoServer(Bundle.main.resourcePath!)
                server.get("/") { params, request, responder in
                    responder(html {
                        "h1" ~ "Hello World !"
                    })
                }
                while true {
                    try server.loop()
                }
            } catch {
                print("Server start error: \(error)")
            }
        }
    }
    
    @IBAction func likedThis(sender: UIButton) {
        
    }
}

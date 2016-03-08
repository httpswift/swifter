//
//  ViewController.swift
//  SwifterSampletvOS
//
//  Created by Damian Kolakowski on 08/03/16.
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import UIKit
import SwiftertvOS

class ViewController: UIViewController {

    private var server: HttpServer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            let server = demoServer(NSBundle.mainBundle().resourcePath!)
            try server.start(9080)
            print("Server has started ( port = 9080 ). Try to connect now...")
            self.server = server
        } catch {
            print("Server start error: \(error)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


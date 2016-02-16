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
        
        let server = HttpServer();
        
        server.get["/upload"] = { r in
            return .OK(.Html("<form method=\"POST\" action=\"/upload\" enctype=\"multipart/form-data\">" +
                "<input name=\"my_file\" type=\"file\"/>" +
                "<button type=\"submit\">Send File</button>" +
            "</form>"))
        }
        server.post["/upload"] = { r in
            if let myFileMultipart = r.parseMultiPartFormData().filter({ $0.name == "my_file" }).first {
                guard let documentsUrl = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first else {
                    return .InternalServerError
                }
                let data: NSData = myFileMultipart.body.withUnsafeBufferPointer { pointer in
                    return NSData(bytes: pointer.baseAddress, length: myFileMultipart.body.count)
                }
                guard let fileSaveUrl = NSURL(string: "name_for_file.txt", relativeToURL: documentsUrl) else {
                    return .InternalServerError
                }
                print(fileSaveUrl)
                data.writeToURL(fileSaveUrl, atomically: true)
                return .OK(.Html("Your file has been uploaded !"))
            }
            return .InternalServerError
        }
        
        do {
            try server.start(9099)
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

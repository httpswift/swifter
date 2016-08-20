//
//  HtmlResponse.swift
//  Swifter
//
//  Created by Dawid Szymczak on 15/08/16.
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

public class HtmlResponse: Response {
    public override func content() -> (contentLength: Int, contentString: String) {
        let serialised = "<html><meta charset=\"UTF-8\"><body>\(String(self.contentObject))</body></html>"
        let data = [UInt8](serialised.utf8)
        return (data.count, serialised)
    }
}
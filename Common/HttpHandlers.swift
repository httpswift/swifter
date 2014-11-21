//
//  Handlers.swift
//  Swifter
//
//  Created by Damian Kolakowski on 14/11/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

class HttpHandlers {

    class func directory(dir: String) -> ( HttpRequest -> HttpResponse ) {
        return { request in
            if let localPath = request.capturedUrlGroups.first {
                let filesPath = dir.stringByExpandingTildeInPath.stringByAppendingPathComponent(localPath)
                if let fileBody = NSData(contentsOfFile: filesPath) {
                    return HttpResponse.RAW(200, fileBody)
                }
            }
            return HttpResponse.NotFound
        }
    }
}
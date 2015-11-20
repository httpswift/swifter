//
//  Handlers.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpHandlers {
    
    private static let rangeExpression = try! NSRegularExpression(pattern: "bytes=(\\d*)-(\\d*)", options: .CaseInsensitive)
    
    public class func directory(dir: String) -> ( HttpRequest -> HttpResponse ) {
        return { request in
            
            guard let localPath = request.capturedUrlGroups.first else {
                return HttpResponse.NotFound
            }
            
            let filesPath = dir.stringByExpandingTildeInPath.stringByAppendingPathComponent(localPath)
            
            guard let fileBody = NSData(contentsOfFile: filesPath) else {
                return HttpResponse.NotFound
            }
            
            if let rangeHeader = request.headers["range"] {
                
                guard let match = rangeExpression.matchesInString(rangeHeader, options: .Anchored, range: NSRange(location: 0, length: rangeHeader.characters.count)).first where match.numberOfRanges == 3 else {
                    return HttpResponse.BadRequest
                }
                
                let startStr = (rangeHeader as NSString).substringWithRange(match.rangeAtIndex(1))
                let endStr = (rangeHeader as NSString).substringWithRange(match.rangeAtIndex(2))
                
                guard let start = Int(startStr), end = Int(endStr) else {
                    return HttpResponse.RAW(200, "OK", nil, fileBody)
                }
                
                let length = end - start
                let range = NSRange(location: start, length: length + 1)
                
                guard range.location + range.length <= fileBody.length else {
                    return HttpResponse.RAW(416, "Requested range not satisfiable", nil, NSData())
                }
                
                let subData = fileBody.subdataWithRange(range)
                
                let headers = [
                    "Content-Range" : "bytes \(startStr)-\(endStr)/\(fileBody.length)"
                ]
                
                print(rangeHeader, headers)
                
                return HttpResponse.RAW(206, "Partial Content", headers, subData)
                
            }
            else {
                return HttpResponse.RAW(200, "OK", nil, fileBody)
            }
            
        }
    }
    
    public class func directoryBrowser(dir: String) -> ( HttpRequest -> HttpResponse ) {
        return { request in
            if let pathFromUrl = request.capturedUrlGroups.first {
                let filePath = dir.stringByExpandingTildeInPath.stringByAppendingPathComponent(pathFromUrl)
                let fileManager = NSFileManager.defaultManager()
                var isDir: ObjCBool = false;
                if ( fileManager.fileExistsAtPath(filePath, isDirectory: &isDir) ) {
                    if ( isDir ) {
                        do {
                            let files = try fileManager.contentsOfDirectoryAtPath(filePath)
                            var response = "<h3>\(filePath)</h3></br><table>"
                            response += files.map({ "<tr><td><a href=\"\(request.url)/\($0)\">\($0)</a></td></tr>"}).joinWithSeparator("")
                            response += "</table>"
                            return HttpResponse.OK(.Html(response))
                        } catch  {
                            return HttpResponse.NotFound
                        }
                    } else {
                        if let fileBody = NSData(contentsOfFile: filePath) {
                            return HttpResponse.RAW(200, "OK", nil, fileBody)
                        }
                    }
                }
            }
            return HttpResponse.NotFound
        }
    }
}

private extension String {
    var stringByExpandingTildeInPath: String {
        return (self as NSString).stringByExpandingTildeInPath
    }
    
    func stringByAppendingPathComponent(str: String) -> String {
        return (self as NSString).stringByAppendingPathComponent(str)
    }
}

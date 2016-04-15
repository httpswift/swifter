//
//  HttpHandlers+Files.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

extension HttpHandlers {
    
    public class func shareFilesFromDirectory(_ directoryPath: String) -> (HttpRequest -> HttpResponse) {
        return { r in
            guard let fileRelativePath = r.params.first else {
                return .NotFound
            }
            let absolutePath = directoryPath + "/" + fileRelativePath.1
            guard let file = try? File.openForReading(absolutePath) else {
                return .NotFound
            }
            return .RAW(200, "OK", [:], { writer in
                var buffer = [UInt8](repeating: 0, count: 64)
                while let count = try? file.read(&buffer) where count > 0 {
                    writer.write(buffer[0..<count])
                }
                file.close()
            })
        }
    }
    
    private static let rangePrefix = "bytes="
    
    public class func directory(_ dir: String) -> (HttpRequest -> HttpResponse) {
        return { r in
            
            guard let localPath = r.params.first else {
                return HttpResponse.NotFound
            }
            
            let filesPath = dir + "/" + localPath.1
            
            guard let fileBody = NSData(contentsOfFile: filesPath) else {
                return HttpResponse.NotFound
            }
            
            if let rangeHeader = r.headers["range"] {
                
                guard rangeHeader.hasPrefix(HttpHandlers.rangePrefix) else {
                    return .BadRequest(.Text("Invalid value of 'Range' header: \(r.headers["range"])"))
                }
                
                #if os(Linux)
                    let rangeString = rangeHeader.substringFromIndex(HttpHandlers.rangePrefix.characters.count)
                #else
                    let rangeString = rangeHeader.substring(from: rangeHeader.startIndex.advanced(by: HttpHandlers.rangePrefix.characters.count))
                #endif
                
                let rangeStringExploded = rangeString.split("-")
                
                guard rangeStringExploded.count == 2 else {
                    return .BadRequest(.Text("Invalid value of 'Range' header: \(r.headers["range"])"))
                }
                
                let startStr = rangeStringExploded[0]
                let endStr   = rangeStringExploded[1]
                
                guard let start = Int(startStr), end = Int(endStr) else {
                    var array = [UInt8](repeating: 0, count: fileBody.length)
                    fileBody.getBytes(&array, length: fileBody.length)
                    return HttpResponse.RAW(200, "OK", nil, { $0.write(array) })
                }
                
                let chunkLength = end - start
                let chunkRange = NSRange(location: start, length: chunkLength + 1)
                
                guard chunkRange.location + chunkRange.length <= fileBody.length else {
                    return HttpResponse.RAW(416, "Requested range not satisfiable", nil, nil)
                }
                
                let chunk = fileBody.subdata(with: chunkRange)
                
                let headers = [ "Content-Range" : "bytes \(startStr)-\(endStr)/\(fileBody.length)" ]
                
                var content = [UInt8](repeating: 0, count: chunk.length)
                chunk.getBytes(&content, length: chunk.length)
                return HttpResponse.RAW(206, "Partial Content", headers, { $0.write(content) })
            } else {
                var content = [UInt8](repeating: 0, count: fileBody.length)
                fileBody.getBytes(&content, length: fileBody.length)
                return HttpResponse.RAW(200, "OK", nil, { $0.write(content) })
            }
        }
    }
    
    public class func directoryBrowser(_ dir: String) -> (HttpRequest -> HttpResponse) {
        return { r in
            guard let (_, value) = r.params.first else {
                return HttpResponse.NotFound
            }
            let filePath = dir + "/" + value
            let fileManager = NSFileManager.defaultManager()
            var isDir: ObjCBool = false
            guard fileManager.fileExists(atPath: filePath, isDirectory: &isDir) else {
                return HttpResponse.NotFound
            }
            if isDir {
                do {
                    let files = try fileManager.contentsOfDirectory(atPath: filePath)
                    var response = "<h3>\(filePath)</h3></br><table>"
                    response += files.map({ "<tr><td><a href=\"\(r.path)/\($0)\">\($0)</a></td></tr>"}).joined(separator: "")
                    response += "</table>"
                    return HttpResponse.OK(.Html(response))
                } catch {
                    return HttpResponse.NotFound
                }
            } else {
                if let content = NSData(contentsOfFile: filePath) {
                    var array = [UInt8](repeating: 0, count: content.length)
                    content.getBytes(&array, length: content.length)
                    return HttpResponse.RAW(200, "OK", nil, { $0.write(array) })
                }
                return HttpResponse.NotFound
            }
        }
    }
}
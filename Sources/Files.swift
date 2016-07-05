//
//  HttpHandlers+Files.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public func shareFilesFromDirectory(directoryPath: String) -> (HttpRequest -> HttpResponse) {
    return { r in
        guard let fileRelativePath = r.params.first else {
            return .NotFound
        }
        let absolutePath = directoryPath + "/" + fileRelativePath.1
        guard let file = try? File.openForReading(absolutePath) else {
            return .NotFound
        }
        return .RAW(200, "OK", [:], { writer in
            writer.write(file)
            file.close()
        })
    }
}

private func fileNameToShare(directoryPath: String, request: HttpRequest) -> String? {
    let path = request.path
    let fileRelativePath = request.params.first

    if !path.hasSuffix("/"), let fileRelativePath = fileRelativePath {
        let absolutePath = directoryPath + "/" + fileRelativePath.1
        return absolutePath
    }

    let fm = NSFileManager.defaultManager()
    let possibleIndexFiles = ["index.html", "index.htm"] // add any other files you want to check for here
    var folderPath = directoryPath
    if let fileRelativePath = fileRelativePath {
        folderPath += "/\(fileRelativePath.1)"
    }

    for indexFile in possibleIndexFiles {
        let indexPath = "\(folderPath)/\(indexFile)"
        if fm.fileExistsAtPath(indexPath) {
            return indexPath
        }
    }
    
    return nil
}

let rangePrefix = "bytes="

public func directory(dir: String) -> (HttpRequest -> HttpResponse) {
    return { r in
        
        guard let localPath = r.params.first else {
            return HttpResponse.NotFound
        }
        
        let filesPath = dir + "/" + localPath.1
        
        guard let fileBody = NSData(contentsOfFile: filesPath) else {
            return HttpResponse.NotFound
        }
        
        if let rangeHeader = r.headers["range"] {
            
            guard rangeHeader.hasPrefix(rangePrefix) else {
                return .BadRequest(.Text("Invalid value of 'Range' header: \(r.headers["range"])"))
            }
            
            #if os(Linux)
                let rangeString = rangeHeader.substringFromIndex(HttpHandlers.rangePrefix.characters.count)
            #else
                let rangeString = rangeHeader.substringFromIndex(rangeHeader.startIndex.advancedBy(rangePrefix.characters.count))
            #endif
            
            let rangeStringExploded = rangeString.split("-")
            
            guard rangeStringExploded.count == 2 else {
                return .BadRequest(.Text("Invalid value of 'Range' header: \(r.headers["range"])"))
            }
            
            let startStr = rangeStringExploded[0]
            let endStr   = rangeStringExploded[1]
            
            guard let start = Int(startStr), end = Int(endStr) else {
                var array = [UInt8](count: fileBody.length, repeatedValue: 0)
                fileBody.getBytes(&array, length: fileBody.length)
                return HttpResponse.RAW(200, "OK", nil, { $0.write(array) })
            }
            
            let chunkLength = end - start
            let chunkRange = NSRange(location: start, length: chunkLength + 1)
            
            guard chunkRange.location + chunkRange.length <= fileBody.length else {
                return HttpResponse.RAW(416, "Requested range not satisfiable", nil, nil)
            }
            
            let chunk = fileBody.subdataWithRange(chunkRange)
            
            let headers = [ "Content-Range" : "bytes \(startStr)-\(endStr)/\(fileBody.length)" ]
            
            var content = [UInt8](count: chunk.length, repeatedValue: 0)
            chunk.getBytes(&content, length: chunk.length)
            return HttpResponse.RAW(206, "Partial Content", headers, { $0.write(content) })
        } else {
            var content = [UInt8](count: fileBody.length, repeatedValue: 0)
            fileBody.getBytes(&content, length: fileBody.length)
            return HttpResponse.RAW(200, "OK", nil, { $0.write(content) })
        }
    }
}

public func directoryBrowser(dir: String) -> (HttpRequest -> HttpResponse) {
    return { r in
        guard let (_, value) = r.params.first else {
            return HttpResponse.NotFound
        }
        let filePath = dir + "/" + value
        do {
            guard try File.exists(filePath) else {
                return HttpResponse.NotFound
            }
            if try File.isDirectory(filePath) {
                let files = try File.list(filePath)
                return scopes {
                    html {
                        body {
                            table(files) { file in
                                tr {
                                    td {
                                        a {
                                            href = r.path + "/" + file
                                            inner = file
                                        }
                                    }
                                }
                            }
                        }
                    }
                }(r)
            } else {
                guard let file = try? File.openForReading(filePath) else {
                    return .NotFound
                }
                return .RAW(200, "OK", [:], { writer in
                    writer.write(file)
                    file.close()
                })
            }
        } catch {
            return HttpResponse.InternalServerError
        }
    }
}

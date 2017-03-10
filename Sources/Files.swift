//
//  HttpHandlers+Files.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

/*
public func shareFile(_ path: String) {
    return { r in
        if let file = try? path.openForReading() {
            return .raw(200, "OK", [:], { writer in
                try? writer.write(file)
                file.close()
            })
        }
        return .notFound
    }
}*/

#if os(iOS) || os(Linux)
    
func fileZeroCopy(from: Int32, to: Int32) {
    var buffer = [UInt8](repeating: 0, count: 1024)
    while true {
        let readResult = read(source, &buffer, buffer.count)
        guard readResult > 0 else {
            return Int32(readResult)
        }
        var writeCounter = 0
        while writeCounter < readResult {
            let writeResult = write(target, &buffer + writeCounter, readResult - writeCounter)
            guard writeResult > 0 else {
                return Int32(writeResult)
            }
            writeCounter = writeCounter + writeResult
        }
    }
}

#else

func fileZeroCopy(from: Int32, to: Int32) {
    var offset: off_t = 0
    var sf: sf_hdtr = sf_hdtr()
    sendfile(from, to, 0, &offset, &sf, 0)
}

#endif

@available(OSXApplicationExtension 10.10, *)
public func share(filesAtPath path: String, defaults: [String] = ["index.html", "default.html"]) -> (([String: String], Request, @escaping ((Response) -> Void)) -> Void) {
        return { (params, request, responder) in
            DispatchQueue.global(qos: .background).async {
                guard let fileRelativePath = params.first else {
                    return responder(404)
                }
                if fileRelativePath.value.isEmpty {
                    for path in defaults {
                        if let file = try? (path + String.pathSeparator + path).openFile(forMode: "r+b") {
                            fileZeroCopy(from: fileno(file.pointer), to: 0)
                            file.close()
                        }
                    }
                }
                if let file = try? (path + String.pathSeparator + fileRelativePath.value).openFile(forMode: "r+b") {
                    fileZeroCopy(from: fileno(file.pointer), to: 0)
                    file.close()
                }
                return responder(404)
            }
        }
}

/*

public func directoryBrowser(_ dir: String) -> (([String: String], Request, @escaping ((Response) -> Void)) -> Void) {
    return { r in
        guard let (_, value) = r.params.first else {
            return HttpResponse.notFound
        }
        let filePath = dir + String.pathSeparator + value
        do {
            guard try filePath.exists() else {
                return .notFound
            }
            if try filePath.directory() {
                let files = try filePath.files()
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
                guard let file = try? filePath.openForReading() else {
                    return .notFound
                }
                return .raw(200, "OK", [:], { writer in
                    try? writer.write(file)
                    file.close()
                })
            }
        } catch {
            return HttpResponse.internalServerError
        }
    }
}*/

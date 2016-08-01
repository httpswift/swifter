//
//  HttpHandlers+Files.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public func shareFilesFromDirectory(_ directoryPath: String) -> ((HttpRequest) -> HttpResponse) {
    return { r in
        guard let fileRelativePath = r.params.first else {
            return .notFound
        }
        let absolutePath = directoryPath + "/" + fileRelativePath.1
        guard let file = try? File.openForReading(absolutePath) else {
            return .notFound
        }
        return .raw(200, "OK", [:], { writer in
            writer.write(file)
            file.close()
        })
    }
}

public func directoryBrowser(_ dir: String) -> ((HttpRequest) -> HttpResponse) {
    return { r in
        guard let (_, value) = r.params.first else {
            return HttpResponse.notFound
        }
        let filePath = dir + "/" + value
        do {
            guard try File.exists(filePath) else {
                return HttpResponse.notFound
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
                    return .notFound
                }
                return .raw(200, "OK", [:], { writer in
                    writer.write(file)
                    file.close()
                })
            }
        } catch {
            return HttpResponse.internalServerError
        }
    }
}


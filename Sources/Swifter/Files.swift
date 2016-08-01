//
//  HttpHandlers+Files.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public func shareFilesFromDirectory(_ directoryPath: String, defaults: [String] = ["index.html", "default.html"]) -> ((HttpRequest) -> HttpResponse) {
    return { r in
        guard let fileRelativePath = r.params.first else {
            return .notFound
        }
        if fileRelativePath.value.isEmpty {
            for path in defaults {
                if let file = try? File.openForReading(directoryPath + File.PATH_SEPARATOR + path) {
                    return .raw(200, "OK", [:], { writer in
                        writer.write(file)
                        file.close()
                    })
                }
            }
        }
        if let file = try? File.openForReading(directoryPath + File.PATH_SEPARATOR + fileRelativePath.value) {
            return .raw(200, "OK", [:], { writer in
                writer.write(file)
                file.close()
            })
        }
        return .notFound
    }
}

public func directoryBrowser(_ dir: String) -> ((HttpRequest) -> HttpResponse) {
    return { r in
        guard let (_, value) = r.params.first else {
            return HttpResponse.notFound
        }
        let filePath = dir + File.PATH_SEPARATOR + value
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


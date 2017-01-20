//
//  HttpHandlers+Files.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public func shareFile(_ path: String) -> ((HttpRequest) -> HttpResponse) {
    return { r in
        if let file = try? path.openForReading() {
            return .raw(200, "OK", [:], { writer in
                try? writer.write(file)
                file.close()
            })
        }
        return .notFound
    }
}

public func shareFilesFromDirectory(_ directoryPath: String, defaults: [String] = ["index.html", "default.html"]) -> ((HttpRequest) -> HttpResponse) {
    return { r in
        guard let fileRelativePath = r.params.first else {
            return .notFound
        }
        if fileRelativePath.value.isEmpty {
            for path in defaults {
                if let file = try? (directoryPath + String.pathSeparator + path).openForReading() {
                    return .raw(200, "OK", [:], { writer in
                        try? writer.write(file)
                        file.close()
                    })
                }
            }
        }
        if let file = try? (directoryPath + String.pathSeparator + fileRelativePath.value).openForReading() {
            return .raw(200, "OK", [:], { writer in
                try? writer.write(file)
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
}

//
//  HttpHandlers+Files.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

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

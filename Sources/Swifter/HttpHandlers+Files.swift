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
}

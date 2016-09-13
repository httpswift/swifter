//
//  File.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

public enum FileError: Error {
    case openFailed(String)
    case writeFailed(String)
    case readFailed(String)
    case seekFailed(String)
    case getCurrentWorkingDirectoryFailed(String)
    case isDirectoryFailed(String)
    case openDirFailed(String)
}

open class File {
    
    open static func openNewForWriting(_ path: String) throws -> File {
        return try openFileForMode(path, "wb")
    }
    
    open static func openForReading(_ path: String) throws -> File {
        return try openFileForMode(path, "rb")
    }
    
    open static func openForWritingAndReading(_ path: String) throws -> File {
        return try openFileForMode(path, "r+b")
    }
    
    open static func openFileForMode(_ path: String, _ mode: String) throws -> File {
        let file = path.withCString({ pathPointer in mode.withCString({ fopen(pathPointer, $0) }) })
        guard file != nil else {
            throw FileError.openFailed(Errno.description())
        }
        return File(file!)
    }
    
    open static func isDirectory(_ path: String) throws -> Bool {
        var s = stat()
        guard path.withCString({ stat($0, &s) }) == 0 else {
            throw FileError.isDirectoryFailed(Errno.description())
        }
        return s.st_mode & S_IFMT == S_IFDIR
    }
    
    open static func currentWorkingDirectory() throws -> String {
        let path = getcwd(nil, 0)
        if path == nil {
            throw FileError.getCurrentWorkingDirectoryFailed(Errno.description())
        }
        guard let result = String(validatingUTF8: path!) else {
            throw FileError.getCurrentWorkingDirectoryFailed("Could not convert getcwd(...)'s result to String.")
        }
        return result
    }
    
    open static func exists(_ path: String) throws -> Bool {
        var buffer = stat()
        return path.withCString({ stat($0, &buffer) == 0 })
    }
    
    open static func list(_ path: String) throws -> [String] {
        let dir = path.withCString { opendir($0) }
        if dir == nil {
            throw FileError.openDirFailed(Errno.description())
        }
        defer { closedir(dir) }
        var results = [String]()
        while case let ent = readdir(dir) , ent != nil {
            var name = ent?.pointee.d_name
            let fileName = withUnsafePointer(to: &name) { (ptr) -> String? in
                #if os(Linux)
                    return String.fromCString([CChar](UnsafeBufferPointer<CChar>(start: UnsafePointer(unsafeBitCast(ptr, UnsafePointer<CChar>.self)), count: Int(NAME_MAX))))
                #else
                    var buffer = [CChar](UnsafeBufferPointer(start: unsafeBitCast(ptr, to: UnsafePointer<CChar>.self), count: Int((ent?.pointee.d_namlen)!)))
                    buffer.append(0)
                    return String(cString: buffer)
                #endif
            }
            if let fileName = fileName {
                results.append(fileName)
            }
        }
        return results
    }
    
    let pointer: UnsafeMutablePointer<FILE>
    
    public init(_ pointer: UnsafeMutablePointer<FILE>) {
        self.pointer = pointer
    }
    
    open func close() -> Void {
        fclose(pointer)
    }
    
    open func read(_ data: inout [UInt8]) throws -> Int {
        if data.count <= 0 {
            return data.count
        }
        let count = fread(&data, 1, data.count, self.pointer)
        if count == data.count {
            return count
        }
        if feof(self.pointer) != 0 {
            return count
        }
        if ferror(self.pointer) != 0 {
            throw FileError.readFailed(Errno.description())
        }
        throw FileError.readFailed("Unknown file read error occured.")
    }

    open func write(_ data: [UInt8]) throws -> Void {
        if data.count <= 0 {
            return
        }
        try data.withUnsafeBufferPointer {
            if fwrite($0.baseAddress, 1, data.count, self.pointer) != data.count {
                throw FileError.writeFailed(Errno.description())
            }
        }
    }
    
    open func seek(_ offset: Int) throws -> Void {
        if fseek(self.pointer, offset, SEEK_SET) != 0 {
            throw FileError.seekFailed(Errno.description())
        }
    }

}

public func withNewFileOpenedForWriting<Result>(_ path: String, _ f: (File) throws -> Result) throws -> Result {
    return try withFileOpenedForMode(path, mode: "wb", f)
}

public func withFileOpenedForReading<Result>(_ path: String, _ f: (File) throws -> Result) throws -> Result {
    return try withFileOpenedForMode(path, mode: "rb", f)
}

public func withFileOpenedForWritingAndReading<Result>(_ path: String, _ f: (File) throws -> Result) throws -> Result {
    return try withFileOpenedForMode(path, mode: "r+b", f)
}

public func withFileOpenedForMode<Result>(_ path: String, mode: String, _ f: (File) throws -> Result) throws -> Result {
    let file = try File.openFileForMode(path, mode)
    defer {
        file.close()
    }
    return try f(file)
}


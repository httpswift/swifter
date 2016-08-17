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

public class File {
    
    public static var PATH_SEPARATOR = "/"
    
    public static func openNewForWriting(_ path: String) throws -> File {
        return try openFileForMode(path, "wb")
    }
    
    public static func openForReading(_ path: String) throws -> File {
        return try openFileForMode(path, "rb")
    }
    
    public static func openForWritingAndReading(_ path: String) throws -> File {
        return try openFileForMode(path, "r+b")
    }
    
    public static func openFileForMode(_ path: String, _ mode: String) throws -> File {
        guard let file = path.withCString({ pathPointer in mode.withCString({ fopen(pathPointer, $0) }) }) else {
            throw FileError.openFailed(descriptionOfLastError())
        }
        return File(file)
    }
    
    public static func isDirectory(_ path: String) throws -> Bool {
        var s = stat()
        guard stat(path, &s) == 0 else {
            throw FileError.isDirectoryFailed(descriptionOfLastError())
        }
        return s.st_mode & S_IFMT == S_IFDIR
    }
    
    public static func currentWorkingDirectory() throws -> String {
        guard let path = getcwd(nil, 0) else {
            throw FileError.getCurrentWorkingDirectoryFailed(descriptionOfLastError())
        }
        return String(cString: path)
    }
    
    public static func exists(_ path: String) throws -> Bool {
        var buffer = stat()
        return path.withCString({ stat($0, &buffer) == 0 })
    }
    
    public static func list(_ path: String) throws -> [String] {
        let dir = path.withCString { opendir($0) }
        if dir == nil {
            throw FileError.openDirFailed(descriptionOfLastError())
        }
        defer { closedir(dir) }
        var results = [String]()
        while true {
            guard let ent = readdir(dir) else {
                break
            }
            var name = ent.pointee.d_name
            let fileName = withUnsafePointer(to: &name) { (ptr) -> String? in
                #if os(Linux)
                    return String.fromCString([CChar](UnsafeBufferPointer<CChar>(start: UnsafePointer(unsafeBitCast(ptr, UnsafePointer<CChar>.self)), count: 256)))
                #else
                    var buffer = [CChar](UnsafeBufferPointer(start: unsafeBitCast(ptr, to: UnsafePointer<CChar>.self), count: Int(ent.pointee.d_namlen)))
                    buffer.append(0)
                    return String(validatingUTF8: buffer)
                #endif
            }
            if let fileName = fileName {
                results.append(fileName)
            }
        }
        return results
    }
    
    internal let pointer: UnsafeMutablePointer<FILE>
    
    public init(_ pointer: UnsafeMutablePointer<FILE>) {
        self.pointer = pointer
    }
    
    public func close() -> Void {
        fclose(pointer)
    }
    
    public func read(_ data: inout [UInt8]) throws -> Int {
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
            throw FileError.readFailed(File.descriptionOfLastError())
        }
        throw FileError.readFailed("Unknown file read error occured.")
    }

    public func write(_ data: [UInt8]) throws -> Void {
        if data.count <= 0 {
            return
        }
        try data.withUnsafeBufferPointer {
            if fwrite($0.baseAddress, 1, data.count, self.pointer) != data.count {
                throw FileError.writeFailed(File.descriptionOfLastError())
            }
        }
    }
    
    public func seek(_ offset: Int) throws -> Void {
        if fseek(self.pointer, offset, SEEK_SET) != 0 {
            throw FileError.seekFailed(File.descriptionOfLastError())
        }
    }
    
    private static func descriptionOfLastError() -> String {
        return String(cString: UnsafePointer(strerror(errno)))
    }
}

public func withNewFileOpenedForWriting<Result>(path: String, _ f: (File) throws -> Result) throws -> Result {
    return try withFileOpenedForMode(path, "wb", f)
}

public func withFileOpenedForReading<Result>(path: String, _ f: (File) throws -> Result) throws -> Result {
    return try withFileOpenedForMode(path, "rb", f)
}

public func withFileOpenedForWritingAndReading<Result>(path: String, _ f: (File) throws -> Result) throws -> Result {
    return try withFileOpenedForMode(path, "r+b", f)
}

public func withFileOpenedForMode<Result>(_ path: String, _ mode: String, _ f: (File) throws -> Result) throws -> Result {
    let file = try File.openFileForMode(path, mode)
    defer {
        file.close()
    }
    return try f(file)
}

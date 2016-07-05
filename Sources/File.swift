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

public enum FileError: ErrorType {
    case OpenFailed(String)
    case WriteFailed(String)
    case ReadFailed(String)
    case SeekFailed(String)
    case GetCurrentWorkingDirectoryFailed(String)
    case IsDirectoryFailed(String)
    case OpenDirFailed(String)
}

public class File {
    
    public static func openNewForWriting(path: String) throws -> File {
        return try openFileForMode(path, "wb")
    }
    
    public static func openForReading(path: String) throws -> File {
        return try openFileForMode(path, "rb")
    }
    
    public static func openForWritingAndReading(path: String) throws -> File {
        return try openFileForMode(path, "r+b")
    }
    
    public static func openFileForMode(path: String, _ mode: String) throws -> File {
        let file = path.withCString({ pathPointer in mode.withCString({ fopen(pathPointer, $0) }) })
        guard file != nil else {
            throw FileError.OpenFailed(descriptionOfLastError())
        }
        return File(file)
    }
    
    public static func isDirectory(path: String) throws -> Bool {
        var s = stat()
        guard path.withCString({ stat($0, &s) }) == 0 else {
            throw FileError.IsDirectoryFailed(descriptionOfLastError())
        }
        return s.st_mode & S_IFMT == S_IFDIR
    }
    
    public static func currentWorkingDirectory() throws -> String {
        let path = getcwd(nil, 0)
        if path == nil {
            throw FileError.GetCurrentWorkingDirectoryFailed(descriptionOfLastError())
        }
        guard let result = String.fromCString(path) else {
            throw FileError.GetCurrentWorkingDirectoryFailed("Could not convert getcwd(...)'s result to String.")
        }
        return result
    }
    
    public static func exists(path: String) throws -> Bool {
        var buffer = stat()
        return path.withCString({ stat($0, &buffer) == 0 })
    }
    
    public static func list(path: String) throws -> [String] {
        let dir = path.withCString { opendir($0) }
        if dir == nil {
            throw FileError.OpenDirFailed(descriptionOfLastError())
        }
        defer { closedir(dir) }
        var results = [String]()
        while true {
            let ent = readdir(dir)
            if ent == nil {
                break
            }
            var name = ent.memory.d_name
            let fileName = withUnsafePointer(&name) { (ptr) -> String? in
                #if os(Linux)
                    return String.fromCString([CChar](UnsafeBufferPointer<CChar>(start: UnsafePointer(unsafeBitCast(ptr, UnsafePointer<CChar>.self)), count: Int(NAME_MAX))))
                #else
                    var buffer = [CChar](UnsafeBufferPointer(start: unsafeBitCast(ptr, UnsafePointer<CChar>.self), count: Int(ent.memory.d_namlen)))
                    buffer.append(0)
                    return String.fromCString(buffer)
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
    
    public func close() -> Void {
        fclose(pointer)
    }
    
    public func read(inout data: [UInt8]) throws -> Int {
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
            throw FileError.ReadFailed(File.descriptionOfLastError())
        }
        throw FileError.ReadFailed("Unknown file read error occured.")
    }

    public func write(data: [UInt8]) throws -> Void {
        if data.count <= 0 {
            return
        }
        try data.withUnsafeBufferPointer {
            if fwrite($0.baseAddress, 1, data.count, self.pointer) != data.count {
                throw FileError.WriteFailed(File.descriptionOfLastError())
            }
        }
    }
    
    public func seek(offset: Int) throws -> Void {
        if fseek(self.pointer, offset, SEEK_SET) != 0 {
            throw FileError.SeekFailed(File.descriptionOfLastError())
        }
    }
    
    private static func descriptionOfLastError() -> String {
        return String.fromCString(UnsafePointer(strerror(errno))) ?? "Error: \(errno)"
    }
}

extension File {
    
    public static func withNewFileOpenedForWriting<Result>(path: String, _ f: File throws -> Result) throws -> Result {
        return try withFileOpenedForMode(path, mode: "wb", f)
    }
    
    public static func withFileOpenedForReading<Result>(path: String, _ f: File throws -> Result) throws -> Result {
        return try withFileOpenedForMode(path, mode: "rb", f)
    }
    
    public static func withFileOpenedForWritingAndReading<Result>(path: String, _ f: File throws -> Result) throws -> Result {
        return try withFileOpenedForMode(path, mode: "r+b", f)
    }
    
    public static func withFileOpenedForMode<Result>(path: String, mode: String, _ f: File throws -> Result) throws -> Result {
        let file = try File.openFileForMode(path, mode)
        defer {
            file.close()
        }
        return try f(file)
    }
}

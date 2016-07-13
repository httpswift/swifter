//
//  Socket+File.swift
//  Swifter
//
//  Created by Damian Kolakowski on 13/07/16.
//

import Foundation

extension Socket {
    
    public func writeFile(file: File) throws -> Void {
        var offset: off_t = 0
        let result = sendfile(fileno(file.pointer), self.socketFileDescriptor, 0, &offset, nil, 0)
        if result == -1 {
            throw SocketError.WriteFailed("sendfile: " + Errno.description())
        }
    }
    
}

#if os(Linux)
    
import Glibc

struct sf_hdtr { }

func sendfile(source: Int32, _ target: Int32, _: off_t, _: UnsafeMutablePointer<off_t>, _: UnsafeMutablePointer<sf_hdtr>, _: Int32) -> Int32 {
    var buffer = [UInt8](count: 1024, repeatedValue: 0)
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

public class NSLock {
    
    private var mutex = pthread_mutex_t()
    
    init() { pthread_mutex_init(&mutex, nil) }
    
    public func lock() { pthread_mutex_lock(&mutex) }
    
    public func unlock() { pthread_mutex_unlock(&mutex) }
    
    deinit { pthread_mutex_destroy(&mutex) }
}


let DISPATCH_QUEUE_PRIORITY_BACKGROUND = 0

private class dispatch_context {
    let block: ((Void) -> Void)
    init(_ block: ((Void) -> Void)) {
        self.block = block
    }
}

func dispatch_get_global_queue(queueId: Int, _ arg: Int) -> Int { return 0 }

func dispatch_async(queueId: Int, _ block: ((Void) -> Void)) {
    let unmanagedDispatchContext = Unmanaged.passRetained(dispatch_context(block))
    let context = UnsafeMutablePointer<Void>(unmanagedDispatchContext.toOpaque())
    var pthread: pthread_t = 0
    pthread_create(&pthread, nil, { (context: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<Void> in
        let unmanaged = Unmanaged<dispatch_context>.fromOpaque(COpaquePointer(context))
        unmanaged.takeUnretainedValue().block()
        unmanaged.release()
        return context
        }, context)
}
    
#endif

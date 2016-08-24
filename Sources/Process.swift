//
//  Process
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

open class Process {
    
    open static var PID: Int {
        return Int(getpid())
    }
    
    open static var TID: UInt64 {
        #if os(Linux)
            return UInt64(pthread_self())
        #else
            var tid: __uint64_t = 0
            pthread_threadid_np(nil, &tid);
            return UInt64(tid)
        #endif
    }
    
    fileprivate static var signalsWatchers = Array<(Int32) -> Void>()
    fileprivate static var signalsObserved = false
    
    open static func watchSignals(_ callback: @escaping (Int32) -> Void) {
        if !signalsObserved {
            [SIGTERM, SIGHUP, SIGSTOP, SIGINT].forEach { item in
                signal(item) {
                    signum in Process.signalsWatchers.forEach { $0(signum) }
                }
            }
            signalsObserved = true
        }
        signalsWatchers.append(callback)
    }
}

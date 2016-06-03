//
//  Process
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public class Process {
    
    public static var PID: Int { return Int(getpid()) }
    
    public typealias SignalCallback = (Int32) -> Void
    
    private static var signalsWatchers = [SignalCallback]()
    private static var signalsObserved = false
    
    public static func watchSignals(_ callback: SignalCallback) {
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

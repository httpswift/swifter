//
//  Process
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public class Process {
    
    public static var PID: Int { return Int(getpid()) }
    
    public typealias SignalCallback = Int32 -> Void
    
    private static var signalsWatchers = [SignalCallback]()
    private static var signalsObserved = false
    
    public static func watchSignals(callback: SignalCallback) {
        if !signalsObserved {
            registerSignals()
            signalsObserved = true
        }
        signalsWatchers.append(callback)
    }
    
    private static func handleSignal(signal: Int32) {
        for callback in Process.signalsWatchers {
            callback(signal)
        }
    }
    
    private static func registerSignals() {
        signal(SIGTERM) { signum in Process.handleSignal(signum) }
        signal(SIGHUP ) { signum in Process.handleSignal(signum) }
        signal(SIGSTOP) { signum in Process.handleSignal(signum) }
        signal(SIGTERM) { signum in Process.handleSignal(signum) }
        signal(SIGINFO) { signum in Process.handleSignal(signum) }
        signal(SIGINT ) { signum in Process.handleSignal(signum) }
    }
}

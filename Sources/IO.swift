//
//  OS.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public protocol IO: class {
    
    init(_ port: in_port_t, forceIPv4: Bool, bindAddress: String?) throws
    
    func wait(_ callback: ((IOEvent) -> Void)) throws
    
    func write(_ socket: Int32, _ data: Array<UInt8>, _ done: @escaping ((Void) -> IODoneAction)) throws
    
    func finish(_ socket: Int32)
}

public enum IODoneAction {
    
    case `continue`, terminate
}

public enum IOEvent {
    
    case connect(String, Int32)
    
    case disconnect(String, Int32)
    
    case data(String, Int32, ArraySlice<UInt8>)
}

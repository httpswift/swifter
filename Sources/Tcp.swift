//
//  OS.swift
//  Swifter
//
//  Copyright © 2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public protocol TcpServer: class {
    
    init(_ port: in_port_t, forceIPv4: Bool, bindAddress: String?) throws
    
    func wait(_ callback: ((TcpServerEvent) -> Void)) throws
    
    func write(_ socket: Int32, _ data: Array<UInt8>, _ done: @escaping ((Void) -> TcpWriteDoneAction)) throws
    
    func finish(_ socket: Int32)
}

public enum TcpWriteDoneAction {
    
    case `continue`, terminate
}

public enum TcpServerEvent {
    
    case connect(String, Int32)
    
    case disconnect(String, Int32)
    
    case data(String, Int32, ArraySlice<UInt8>)
}

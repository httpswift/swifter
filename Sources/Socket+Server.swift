//
//  Socket+Server.swift
//  Swifter
//
//  Created by Damian Kolakowski on 13/07/16.
//

import Foundation

extension Socket {

    /// - Parameters:
    ///   - listenAddress: String representation of the address the socket should accept
    ///       connections from. It should be in IPv4 format if forceIPv4 == true,
    ///       otherwise - in IPv6.
    public class func tcpSocketForListen(_ port: in_port_t, _ forceIPv4: Bool = false, _ maxPendingConnection: Int32 = SOMAXCONN, _ listenAddress: String? = nil) throws -> Socket {

        #if os(Linux)
            let socketFileDescriptor = socket(forceIPv4 ? AF_INET : AF_INET6, Int32(SOCK_STREAM.rawValue), 0)
        #else
            let socketFileDescriptor = socket(forceIPv4 ? AF_INET : AF_INET6, SOCK_STREAM, 0)
        #endif

        if socketFileDescriptor == -1 {
            throw SocketError.socketCreationFailed(Errno.description())
        }

        var value: Int32 = 1
        if setsockopt(socketFileDescriptor, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(MemoryLayout<Int32>.size)) == -1 {
            let details = Errno.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.socketSettingReUseAddrFailed(details)
        }
        Socket.setNoSigPipe(socketFileDescriptor)

        var bindResult: Int32 = -1
        if forceIPv4 {
            #if os(Linux)
            var addr = sockaddr_in(
                sin_family: sa_family_t(AF_INET),
                sin_port: port.bigEndian,
                sin_addr: in_addr(s_addr: in_addr_t(0)),
                sin_zero:(0, 0, 0, 0, 0, 0, 0, 0))
            #else
            var addr = sockaddr_in(
                sin_len: UInt8(MemoryLayout<sockaddr_in>.stride),
                sin_family: UInt8(AF_INET),
                sin_port: port.bigEndian,
                sin_addr: in_addr(s_addr: in_addr_t(0)),
                sin_zero:(0, 0, 0, 0, 0, 0, 0, 0))
            #endif
            if let address = listenAddress {
              if address.withCString({ cstring in inet_pton(AF_INET, cstring, &addr.sin_addr) }) == 1 {
                // print("\(address) is converted to \(addr.sin_addr).")
              } else {
                // print("\(address) is not converted.")
              }
            }
            bindResult = withUnsafePointer(to: &addr) {
                bind(socketFileDescriptor, UnsafePointer<sockaddr>(OpaquePointer($0)), socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        } else {
            #if os(Linux)
            var addr = sockaddr_in6(
                sin6_family: sa_family_t(AF_INET6),
                sin6_port: port.bigEndian,
                sin6_flowinfo: 0,
                sin6_addr: in6addr_any,
                sin6_scope_id: 0)
            #else
            var addr = sockaddr_in6(
                sin6_len: UInt8(MemoryLayout<sockaddr_in6>.stride),
                sin6_family: UInt8(AF_INET6),
                sin6_port: port.bigEndian,
                sin6_flowinfo: 0,
                sin6_addr: in6addr_any,
                sin6_scope_id: 0)
            #endif
            if let address = listenAddress {
              if address.withCString({ cstring in inet_pton(AF_INET6, cstring, &addr.sin6_addr) }) == 1 {
                //print("\(address) is converted to \(addr.sin6_addr).")
              } else {
                //print("\(address) is not converted.")
              }
            }
            bindResult = withUnsafePointer(to: &addr) {
                bind(socketFileDescriptor, UnsafePointer<sockaddr>(OpaquePointer($0)), socklen_t(MemoryLayout<sockaddr_in6>.size))
            }
        }

        if bindResult == -1 {
            let details = Errno.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.bindFailed(details)
        }

        if listen(socketFileDescriptor, maxPendingConnection) == -1 {
            let details = Errno.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.listenFailed(details)
        }
        return Socket(socketFileDescriptor: socketFileDescriptor)
    }
    
    public class func localSocketForListen(_ path: String, _ maxPendingConnection: Int32 = SOMAXCONN) throws -> Socket {
        // Create a local (Unix domain) socket
        #if os(Linux)
            let socketFileDescriptor = socket(AF_LOCAL, Int32(SOCK_STREAM.rawValue), 0)
        #else
            let socketFileDescriptor = socket(AF_LOCAL, SOCK_STREAM, 0)
        #endif
        // Verify the socket was created successfully
        if socketFileDescriptor == -1 {
            throw SocketError.socketCreationFailed(Errno.description())
        }
        // Set the Re-Use Address socket option
        var value: Int32 = 1
        if setsockopt(socketFileDescriptor, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(MemoryLayout<Int32>.size)) == -1 {
            // setsockopt failed; close the file discriptor and throw an error
            let details = Errno.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.socketSettingReUseAddrFailed(details)
        }
        // Prevent crashes when blocking calls are pending and the app gets paused
        Socket.setNoSigPipe(socketFileDescriptor)
        // Create the Unix path socket address
        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_LOCAL)
        let pathMax = MemoryLayout.size(ofValue: addr.sun_path)
        let pathLen = Int(withUnsafeMutablePointer(to: &addr.sun_path) {
            $0.withMemoryRebound(to: Int8.self, capacity: pathMax) {
                // Include the null terminator
                return strlcpy($0, path, pathMax) + UInt(1)
            }
        })
        // Ensure the path didn't get truncated
        if pathLen > pathMax {
            Socket.close(socketFileDescriptor)
            throw SocketError.localPathTooLong("\"\(path)\" is \(pathLen) bytes but max is \(pathMax) bytes")
        }
        let sun_len = socklen_t(MemoryLayout<sockaddr_un>.size - pathMax + pathLen)
        #if !os(Linux)
            // Apple has an extra field in sockaddr_un
            addr.sun_len = UInt8(sun_len)
        #endif
        // Bind the socket to the path
        let bindResult = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                return bind(socketFileDescriptor, $0, sun_len)
            }
        }
        if bindResult == -1 {
            let details = Errno.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.bindFailed(details)
        }
        // Enter the listening state
        if listen(socketFileDescriptor, maxPendingConnection) == -1 {
            let details = Errno.description()
            Socket.close(socketFileDescriptor)
            throw SocketError.listenFailed(details)
        }
        return Socket(socketFileDescriptor: socketFileDescriptor)
    }

    public func acceptClientSocket() throws -> Socket {
        var addr = sockaddr()
        var len: socklen_t = 0
        let clientSocket = accept(self.socketFileDescriptor, &addr, &len)
        if clientSocket == -1 {
            throw SocketError.acceptFailed(Errno.description())
        }
        Socket.setNoSigPipe(clientSocket)
        return Socket(socketFileDescriptor: clientSocket)
    }
}

//
//  HttpParser.swift
//
//  Created by Damian Kolakowski on 05/06/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

class HttpParser {
    
    class func err(reason:String) -> NSError {
        return NSError.errorWithDomain("HTTP_PARSER", code: 0, userInfo:[NSLocalizedFailureReasonErrorKey : reason])
    }
    
    func nextHttpRequest(socket: CInt, error:NSErrorPointer = nil) -> (String, String, Dictionary<String, String>, NSData?)? {
        if let statusLine = nextLine(socket, error: error) {
            let statusTokens = split(statusLine, { $0 == " " })
            println(statusTokens)
            if ( statusTokens.count < 3 ) {
                if error != nil { error.memory = HttpParser.err("Invalid status line: \(statusLine)") }
                return nil
            }
            let method = statusTokens[0]
            let path = statusTokens[1]
            if let headers = nextHeaders(socket, error: error) {
                var responseString = ""
                while let line = nextLine(socket, error: error)
                {
                    if line.isEmpty {
                        break
                    }
                    responseString += line
                }
                println(responseString)
                let responseData = responseString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
                return (path, method, headers, responseData)
            }
        }
        return nil
    }
    
    func nextHeaders(socket: CInt, error:NSErrorPointer) -> Dictionary<String, String>? {
        var headers = Dictionary<String, String>()
        while let headerLine = nextLine(socket, error: error) {
            if ( headerLine.isEmpty ) {
                return headers
            }
            let headerTokens = split(headerLine, { $0 == ":" })
            if ( headerTokens.count >= 2 ) {
                // RFC 2616 - "Hypertext Transfer Protocol -- HTTP/1.1", paragraph 4.2, "Message Headers":
                // "Each header field consists of a name followed by a colon (":") and the field value. Field names are case-insensitive."
                // We can keep lower case version.
                let headerName = headerTokens[0].lowercaseString
                let headerValue = headerTokens[1]
                if ( !headerName.isEmpty && !headerValue.isEmpty ) {
                    headers.updateValue(headerValue, forKey: headerName)
                }
            }
        }
        return nil
    }

    var recvBuffer: [UInt8] = [UInt8](count: 1024, repeatedValue: 0)
    var recvBufferSize: Int = 0
    var recvBufferOffset: Int = 0
    
    func nextUInt8(socket: CInt) -> Int {
        if ( recvBufferSize == 0 || recvBufferOffset == recvBuffer.count ) {
            recvBufferOffset = 0
            recvBufferSize = recv(socket, &recvBuffer, UInt(recvBuffer.count), MSG_DONTWAIT)
            if ( recvBufferSize <= 0 ) { return recvBufferSize }
            if recvBufferSize < recvBuffer.count
            {
                recvBuffer[recvBufferSize] = 0
            }
        }
        let returnValue = recvBuffer[recvBufferOffset]
        recvBufferOffset++
        return Int(returnValue)
    }
    
    func nextLine(socket: CInt, error:NSErrorPointer) -> String? {
        var characters: String = ""
        var n = 0
        do {
            n = nextUInt8(socket)
            if ( n > 13 /* CR */ ) { characters.append(Character(UnicodeScalar(n))) }
        } while ( n > 0 && n != 10 /* NL */)
        if ( n == -1 && characters.isEmpty ) {
            if error != nil { error.memory = Socket.socketLastError("recv(...) failed.") }
            return nil
        }
        return characters
    }
    
    func supportsKeepAlive(headers: Dictionary<String, String>) -> Bool {
        if let value = headers["connection"] {
            return "keep-alive" == value.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).lowercaseString
        }
        return false
    }
}

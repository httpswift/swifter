//
//  HttpParser.swift
//
//  Created by Damian Kolakowski on 05/06/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

/* HTTP stream parser */

class HttpParser {
    
    func parseHttpHeader(socket: CInt) -> (String, Dictionary<String, String>)? {
        if let statusLine = parseLine(socket) {
            let statusTokens = split(statusLine, { $0 == " " })
            if ( statusTokens.count >= 3 ) {
                let path = statusTokens[1]
                if let headers = parseHeaders(socket) {
                    return (path, headers)
                }
            }
        }
        return nil
    }
    
    func parseHeaders(socket: CInt) -> Dictionary<String, String>? {
        var headers = Dictionary<String, String>()
        while let headerLine = parseLine(socket) {
            if ( headerLine.isEmpty ) {
                return headers
            }
            let headerTokens = split(headerLine, { $0 == ":" })
            if ( headerTokens.count >= 2 ) {
                headers.updateValue(headerTokens[1], forKey: headerTokens[0])
            }
        }
        return nil
    }
    
    func parseLine(socket: CInt) -> String? {
        // TODO - read more bytes than one
        // TODO - check if there is a nicer way to manipulate bytes with Swift ( recv(...) -> String )
        var characters: String = ""
        var buff: UInt8[] = UInt8[](count: 1, repeatedValue: 0), n: Int = 1
        do {
            n = recv(socket, &buff, 1, 0);
            if ( n > 0 && buff[0] > 13 /* CR */ ) {
                characters += Character(UnicodeScalar(UInt32(buff[0])))
            }
        } while ( n > 0 && buff[0] != 10 /* NL */ )
        if ( n == -1 ) {
            return nil
        }
        println("SOCKET LOG [\(socket)] -> \(characters)")
        return characters
    }
}

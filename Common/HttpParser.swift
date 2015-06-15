//
//  HttpParser.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

class HttpParser {
    
    func err(reason: String) -> NSError {
        return NSError(domain: "HttpParser", code: 0, userInfo: [NSLocalizedDescriptionKey : reason])
    }
    
    func nextHttpRequest(socket: CInt, error:NSErrorPointer = nil) -> HttpRequest? {
        if let statusLine = nextLine(socket, error: error) {
            let statusTokens = split(statusLine, isSeparator: { $0 == " " })
            println(statusTokens)
            if ( statusTokens.count < 3 ) {
                if error != nil { error.memory = err("Invalid status line: \(statusLine)") }
                return nil
            }
            var addr = UnsafeMutablePointer<sockaddr_storage>.alloc(1)
            var len = socklen_t(sizeofValue(addr.memory))
            let method = statusTokens[0]
            let path = statusTokens[1]
            let urlParams = extractUrlParams(path)
            var host:String = ""
            if getpeername(socket, UnsafeMutablePointer(addr), &len) != -1 {
                
                var hostBuffer = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                if (getnameinfo(UnsafeMutablePointer(addr), socklen_t(addr.memory.ss_len),
                    &hostBuffer, socklen_t(hostBuffer.count), nil, 0,
                    NI_NUMERICHOST) == 0) {
                        host = String.fromCString(hostBuffer)!
                        //println("socket \(sockfd) ip \(host)")
                }
            }
            addr.dealloc(1)
            // TODO extract query parameters
            if let headers = nextHeaders(socket, error: error) {
                // TODO detect content-type and handle:
                // 'application/x-www-form-urlencoded' -> Dictionary
                // 'multipart' -> Dictionary
                if let contentSize = headers["content-length"]?.toInt() {
                    let body = nextBody(socket, size: contentSize, error: error)
                    
                    return HttpRequest(remoteAddress:host, url: path, urlParams: urlParams, method: method, headers: headers, body: body, capturedUrlGroups: [])
                    
                }
                return HttpRequest(remoteAddress:host, url: path, urlParams: urlParams, method: method, headers: headers, body: nil, capturedUrlGroups: [])
                
            }
        }
        return nil
    }
    
    private func extractUrlParams(url: String) -> [(String, String)] {
        if let query = split(url, isSeparator: { $0 == "?" }).last {
            return map(split(query, isSeparator: { $0 == "&" }), { (param:String) -> (String, String) in
                let tokens = split(param, isSeparator: { $0 == "=" })
                if tokens.count >= 2 {
                    let key = tokens[0].stringByRemovingPercentEncoding
                    let value = tokens[1].stringByRemovingPercentEncoding
                    if key != nil && value != nil { return (key!, value!) }
                }
                return ("","")
            })
        }
        return []
    }
    
    private func nextBody(socket: CInt, size: Int , error:NSErrorPointer) -> String? {
        var body = ""
        var counter = 0;
        while ( counter < size ) {
            let c = nextInt8(socket)
            if ( c < 0 ) {
                if error != nil { error.memory = err("IO error while reading body") }
                return nil
            }
            body.append(UnicodeScalar(c))
            counter++;
        }
        return body
    }
    
    private func nextHeaders(socket: CInt, error:NSErrorPointer) -> Dictionary<String, String>? {
        var headers = Dictionary<String, String>()
        while let headerLine = nextLine(socket, error: error) {
            if ( headerLine.isEmpty ) {
                return headers
            }
            let headerTokens = split(headerLine, isSeparator: { $0 == ":" })
            if ( headerTokens.count >= 2 ) {
                // RFC 2616 - "Hypertext Transfer Protocol -- HTTP/1.1", paragraph 4.2, "Message Headers":
                // "Each header field consists of a name followed by a colon (":") and the field value. Field names are case-insensitive."
                // We can keep lower case version.
                let headerName = headerTokens[0].lowercaseString
                let headerValue = headerTokens[1].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                if ( !headerName.isEmpty && !headerValue.isEmpty ) {
                    headers.updateValue(headerValue, forKey: headerName)
                }
            }
        }
        return nil
    }

    private func nextInt8(socket: CInt) -> Int {
        var buffer = [UInt8](count: 1, repeatedValue: 0);
        let next = recv(socket as Int32, &buffer, Int(buffer.count), 0)
        if next <= 0 { return next }
        return Int(buffer[0])
    }
    
    private func nextLine(socket: CInt, error:NSErrorPointer) -> String? {
        var characters: String = ""
        var n = 0
        do {
            n = nextInt8(socket)
            if ( n > 13 /* CR */ ) { characters.append(Character(UnicodeScalar(n))) }
        } while ( n > 0 && n != 10 /* NL */)
        if ( n == -1 && characters.isEmpty ) {
            if error != nil { error.memory = Socket.lastErr("recv(...) failed.") }
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

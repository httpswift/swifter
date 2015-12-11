//
//  HttpRouter.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpRouter {
    
    private var handlers: [(pattern: [String], handler: HttpServer.Handler)] = []
    
    public func routes() -> [String] {
        return handlers.map { $0.pattern.joinWithSeparator("/") }
    }
    
    public func register(path: String, handler: HttpServer.Handler) {
        handlers.append((path.split("/"), handler))
        handlers.sortInPlace { $0.0.pattern.count < $0.1.pattern.count }
    }
    
    public func unregister(path: String) {
        let p = path.split("/")
        handlers = handlers.filter { (pattern, handler) -> Bool in
            return pattern != p
        }
    }
    
    public func select(url: String) -> ([String: String], HttpServer.Handler)? {
        let urlTokens = url.split("/")
        for (pattern, handler) in handlers {
            if let params = matchParams(pattern, valueTokens: urlTokens) {
                return (params, handler)
            }
        }
        return nil
    }
    
    public func matchParams(patternTokens: [String], valueTokens: [String]) -> [String: String]? {
        var params = [String: String]()
        for index in 0..<valueTokens.count {
            if index >= patternTokens.count {
                return nil
            }
            let patternToken = patternTokens[index]
            let valueToken = valueTokens[index]
            if patternToken.isEmpty {
                if patternToken != valueToken {
                    return nil
                }
            }
            if patternToken.characters.first == ":" {
#if os(Linux)
                params[patternToken.substringFromIndex(1)] = valueToken
#else
                params[patternToken.substringFromIndex(patternToken.characters.startIndex.successor())] = valueToken
#endif
            } else {
                if patternToken != valueToken {
                    return nil
                }
            }
        }
        return params
    }
}

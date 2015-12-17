//
//  HttpRouter.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpRouter {
    private var handlers: [(method: HttpRequest.Method?, pattern: [String],
                            handler: HttpServer.Handler)] = []
    
    public func routes() -> [(method: HttpRequest.Method?, path: String)] {
        return handlers.map { ($0.method, "/" + $0.pattern.joinWithSeparator("/")) }
    }
    
    public func register(path: String, handler: HttpServer.Handler) {
        register(nil, path: path, handler: handler)
    }
    
    public func register(method: HttpRequest.Method?, path: String, handler: HttpServer.Handler) {
        handlers.append((method, path.split("/"), handler))
        handlers.sortInPlace { $0.0.pattern.count < $0.1.pattern.count }
    }
    
    public func unregister(path: String) {
        unregister(nil, path: path)
    }
    
    public func unregister(method: HttpRequest.Method?, path: String) {
        let p = path.split("/")
        handlers = handlers.filter { (meth, pattern, _) -> Bool in
            return meth != method || pattern != p
        }
    }
    
    public func select(method: HttpRequest.Method, url: String)
                      -> ([String: String], HttpServer.Handler)? {
        let urlTokens = url.split("/")
        for (meth, pattern, handler) in handlers {
            if meth == nil || meth! == method {
                if let params = matchParams(pattern, valueTokens: urlTokens) {
                    return (params, handler)
                }
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

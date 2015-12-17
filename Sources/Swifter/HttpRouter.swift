//
//  HttpRouter.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public class HttpRouter {
    
    private var handlers: [(String?, pattern: [String], HttpRequest -> HttpResponse)] = []
    
    public func routes() -> [(method: String?, path: String)] {
        return handlers.map { ($0.0, "/" + $0.pattern.joinWithSeparator("/")) }
    }
    
    public func register(method: String?, path: String, handler: HttpRequest -> HttpResponse) {
        handlers.append((method, path.split("/"), handler))
        handlers.sortInPlace { $0.0.pattern.count < $0.1.pattern.count }
    }
    
    public func unregister(method: String?, path: String) {
        let tokens = path.split("/")
        handlers = handlers.filter { (meth, pattern, _) -> Bool in
            return meth != method || pattern != tokens
        }
    }
    
    public func select(method: String?, url: String) -> ([String: String], HttpRequest -> HttpResponse)? {
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

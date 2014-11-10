//
//  HttpServerHandler.swift
//  Swifter
//
//  Created by Frithjof Schaefer on 10/11/14.
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

class HttpServerHandler {
    typealias Handler = HttpRequest -> HttpResponse
    
    let matchingOptions = NSMatchingOptions(0)
    let expressionOptions = NSRegularExpressionOptions(0)
    
    var handlers: [(expression: NSRegularExpression, handler: Handler)]
    
    init(handlers:  [(expression: NSRegularExpression, handler: Handler)]){
        self.handlers = handlers
    }
    
    subscript (path: String) -> Handler? {
        get {
            for (expression, handler) in handlers {
                let numberOfMatches: Int = expression.numberOfMatchesInString(path, options: matchingOptions, range: NSMakeRange(0, path.lengthOfBytesUsingEncoding(NSASCIIStringEncoding)))
                if ( numberOfMatches > 0 ) {
                    return handler
                }
            }
            return nil
        }
        set ( newValue ) {
            if let regex: NSRegularExpression = NSRegularExpression(pattern: path, options: expressionOptions, error: nil) {
                if let newHandler = newValue {
                    handlers.append(expression: regex, handler: newHandler)
                }
            }
        }
    }
}

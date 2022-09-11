//
//  HttpRespBodyWriter.swift
//  Swifter
//
//  Copyright (c) 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

public enum HttpResponse {
    
    case ok(HttpResponseBody, [String: String] = [:])
    case notFound(HttpResponseBody? = nil)
    case raw(Int, String, [String: String]?, ((HttpResponseBodyWriter) throws -> Void)?)
    
    public var statusCode: Int {
        switch self {
        case .ok                      : return 200
        case .notFound                : return 404
        case .raw(let code, _, _, _)  : return code
        }
    }
    
    public var reasonPhrase: String {
        switch self {
        case .ok                       : return "OK"
        case .notFound                 : return "Not Found"
        case .raw(_, let phrase, _, _) : return phrase
        }
    }
    
    public func headers() -> [String: String] {
        var headers = ["Server": "SwifterLite \(HttpServer.version)"]
        switch self {
        case .ok(let body, let customHeaders):
            for (key, value) in customHeaders {
                headers.updateValue(value, forKey: key)
            }
            switch body {
            //case .json: headers["Content-Type"] = "application/json"
            //case .ping: headers["Content-Type"] = "text/plain"
            case .json(_, let contentType): headers["Content-Type"] = contentType
            case .ping(_, let contentType): headers["Content-Type"] = contentType
            case .data(_, let contentType): headers["Content-Type"] = contentType
            default:break
            }
        case .raw(_, _, let rawHeaders, _):
            if let rawHeaders = rawHeaders {
                for (key, value) in rawHeaders {
                    headers.updateValue(value, forKey: key)
                }
            }
        default:break
        }
        return headers
    }
    
    func content() -> (length: Int, write: ((HttpResponseBodyWriter) throws -> Void)?) {
        switch self {
        case .ok(let body, _)          : return body.content()
        case .notFound(let body)       : return body?.content() ?? (-1, nil)
        case .raw(_, _, _, let writer) : return (-1, writer)
        }
    }
}

//func == (inLeft: HttpResponse, inRight: HttpResponse) -> Bool {
//    inLeft.statusCode == inRight.statusCode
//}

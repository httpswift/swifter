//
//  HttpResponse.swift
//  Swifter
//  Copyright (c) 2015 Damian Kołakowski. All rights reserved.
//

import Foundation

public enum SerializationError: ErrorType {
    case InvalidObject
    case NotSupported
    case EncodingError
}

public enum HttpResponseBody {
    
    case Json(AnyObject)
    case Html(String)
    case Text(String)
    case Custom(Any, (Any) throws -> String)
    
    func data() -> [UInt8]? {
        do {
            switch self {
            case .Json(let object):
                guard let obj = object as? AnyObject where NSJSONSerialization.isValidJSONObject(obj) else {
                    throw SerializationError.InvalidObject
                }
                let json = try NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions.PrettyPrinted)
                return Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(json.bytes), count: json.length))
            case .Text(let body):
                let serialised = body
                return [UInt8](serialised.utf8)
            case .Html(let body):
                let serialised = "<html><meta charset=\"UTF-8\"><body>\(body)</body></html>"
                return [UInt8](serialised.utf8)
            case .Custom(let object, let closure):
                let serialised = try closure(object)
                return [UInt8](serialised.utf8)
            }
        } catch {
            return [UInt8]("Serialisation error: \(error)".utf8)
        }
    }
}

public enum HttpResponse {
    
    case OK(HttpResponseBody), Created, Accepted
    case MovedPermanently(String)
    case BadRequest, Unauthorized, Forbidden, NotFound
    case InternalServerError
    case RAW(Int, String, [String:String]?, [UInt8]?)
    
    func statusCode() -> Int {
        switch self {
        case .OK(_)                   : return 200
        case .Created                 : return 201
        case .Accepted                : return 202
        case .MovedPermanently        : return 301
        case .BadRequest              : return 400
        case .Unauthorized            : return 401
        case .Forbidden               : return 403
        case .NotFound                : return 404
        case .InternalServerError     : return 500
        case .RAW(let code, _ , _, _) : return code
        }
    }
    
    func reasonPhrase() -> String {
        switch self {
        case .OK(_)                    : return "OK"
        case .Created                  : return "Created"
        case .Accepted                 : return "Accepted"
        case .MovedPermanently         : return "Moved Permanently"
        case .BadRequest               : return "Bad Request"
        case .Unauthorized             : return "Unauthorized"
        case .Forbidden                : return "Forbidden"
        case .NotFound                 : return "Not Found"
        case .InternalServerError      : return "Internal Server Error"
        case .RAW(_, let phrase, _, _) : return phrase
        }
    }
    
    func headers() -> [String: String] {
        var headers = ["Server" : "Swifter \(HttpServer.VERSION)"]
        switch self {
        case .OK(let body):
            switch body {
            case .Json(_)   : headers["Content-Type"] = "application/json"
            case .Html(_)   : headers["Content-Type"] = "text/html"
            default:break
            }
        case .MovedPermanently(let location): headers["Location"] = location
        case .RAW(_, _, let rawHeaders, _):
            if let rawHeaders = rawHeaders {
                for (k, v) in rawHeaders {
                    headers.updateValue(v, forKey: k)
                }
            }
        default:break
        }
        return headers
    }
    
    func body() -> [UInt8]? {
        switch self {
        case .OK(let body)           : return body.data()
        case .RAW(_, _, _, let data) : return data
        default                      : return nil
        }
    }
}

/**
    Makes it possible to compare handler responses with '==', but
	ignores any associated values. This should generally be what
	you want. E.g.:
	
    let resp = handler(updatedRequest)
        if resp == .NotFound {
        print("Client requested not found: \(request.url)")
    }
*/

func ==(inLeft: HttpResponse, inRight: HttpResponse) -> Bool {
    return inLeft.statusCode() == inRight.statusCode()
}


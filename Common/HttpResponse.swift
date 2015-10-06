//
//  HttpResponse.swift
//  Swifter
//  Copyright (c) 2014 Damian Kołakowski. All rights reserved.
//

import Foundation

public enum HttpResponseBody {
    
    case JSON(AnyObject)
    case XML(AnyObject)
    case PLIST(AnyObject)
    case HTML(String)
    case STRING(String)
    
    func data() -> String? {
        switch self {
        case .JSON(let object):
            if NSJSONSerialization.isValidJSONObject(object) {
                do {
                    let json = try NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions.PrettyPrinted)
                    if let nsString = NSString(data: json, encoding: NSUTF8StringEncoding) {
                        return nsString as String
                    }
                } catch let serializationError as NSError {
                    return "Serialisation error: \(serializationError)"
                }
            }
            return "Invalid object to serialise."
        case .XML(_):
            return "XML serialization not supported."
        case .PLIST(let object):
            let format = NSPropertyListFormat.XMLFormat_v1_0
            if NSPropertyListSerialization.propertyList(object, isValidForFormat: format) {
                do {
                    let plist = try NSPropertyListSerialization.dataWithPropertyList(object, format: format, options: 0)
                    if let nsString = NSString(data: plist, encoding: NSUTF8StringEncoding) {
                        return nsString as String
                    }
                } catch let serializationError as NSError {
                    return "Serialisation error: \(serializationError)"
                }
            }
            return "Invalid object to serialise."
        case .STRING(let body):
            return body
        case .HTML(let body):
            return "<html><body>\(body)</body></html>"
        }
    }
}

public enum HttpResponse {
    
    case OK(HttpResponseBody), Created, Accepted
    case MovedPermanently(String)
    case BadRequest, Unauthorized, Forbidden, NotFound
    case InternalServerError
    case RAW(Int, String, [String:String]?, NSData)
    
    func statusCode() -> Int {
        switch self {
        case .OK(_)                 : return 200
        case .Created               : return 201
        case .Accepted              : return 202
        case .MovedPermanently      : return 301
        case .BadRequest            : return 400
        case .Unauthorized          : return 401
        case .Forbidden             : return 403
        case .NotFound              : return 404
        case .InternalServerError   : return 500
        case .RAW(let code,_,_,_)   : return code
        }
    }
    
    func reasonPhrase() -> String {
        switch self {
        case .OK(_)                 : return "OK"
        case .Created               : return "Created"
        case .Accepted              : return "Accepted"
        case .MovedPermanently      : return "Moved Permanently"
        case .BadRequest            : return "Bad Request"
        case .Unauthorized          : return "Unauthorized"
        case .Forbidden             : return "Forbidden"
        case .NotFound              : return "Not Found"
        case .InternalServerError   : return "Internal Server Error"
        case .RAW(_,let pharse,_,_) : return pharse
        }
    }
    
    func headers() -> [String: String] {
        var headers = [String:String]()
        headers["Server"] = "Swifter \(HttpServer.VERSION)"
        switch self {
		case .OK(let body):
            switch body {
                case .JSON(_)   : headers["Content-Type"] = "application/json"
                case .PLIST(_)  : headers["Content-Type"] = "application/xml"
                case .XML(_)    : headers["Content-Type"] = "application/xml"
                // 'application/xml' vs 'text/xml'
                // From RFC: http://www.rfc-editor.org/rfc/rfc3023.txt - "If an XML document -- that is, the unprocessed, source XML document -- is readable by casual users,
                // text/xml is preferable to application/xml. MIME user agents (and web user agents) that do not have explicit 
                // support for text/xml will treat it as text/plain, for example, by displaying the XML MIME entity as plain text. 
                // Application/xml is preferable when the XML MIME entity is unreadable by casual users."
                case .HTML(_)   : headers["Content-Type"] = "text/html"
                default:[]
            }
        case .MovedPermanently(let location): headers["Location"] = location
        case .RAW(_,_, let rawHeaders,_):
            if let rawHeaders = rawHeaders {
                for (k, v) in rawHeaders {
                    headers.updateValue(v, forKey: k)
                }
            }
        default:[]
        }
        return headers
    }
    
    func body() -> NSData? {
        switch self {
        case .OK(let body)          : return body.data()?.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        case .RAW(_,_,_, let data)  : return data
        default                     : return nil
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

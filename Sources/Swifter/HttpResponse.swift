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

public protocol Serializer {
    func serialize(object: Any) throws -> String
}

public class JSONSerializer: Serializer {
    public func serialize(object: Any) throws -> String {
        guard let obj = object as? AnyObject where NSJSONSerialization.isValidJSONObject(obj) else {
            throw SerializationError.InvalidObject
        }
        
        let json = try NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions.PrettyPrinted)
        
        guard let string = String(data: json, encoding: NSUTF8StringEncoding) else {
            throw SerializationError.EncodingError
        }
        
        return string
    }
    
    private static func serialize(object: Any) throws -> String {
        let serializer = JSONSerializer()
        return try serializer.serialize(object)
    }
}

public class XMLSerializer: Serializer {
    public func serialize(object: Any) throws -> String {
        throw SerializationError.NotSupported
    }
    
    private static func serialize(object: Any) throws -> String {
        let serializer = XMLSerializer()
        return try serializer.serialize(object)
    }
}

public class PLISTSerializer: Serializer {
    public func serialize(object: Any) throws -> String {
        let format = NSPropertyListFormat.XMLFormat_v1_0
        
        guard let obj = object as? AnyObject where NSPropertyListSerialization.propertyList(obj, isValidForFormat: format) else {
            throw SerializationError.InvalidObject
        }
        
        let plist = try NSPropertyListSerialization.dataWithPropertyList(obj, format: format, options: 0)
        
        guard let string = String(data: plist, encoding: NSUTF8StringEncoding) else {
            throw SerializationError.EncodingError
        }
        
        return string
    }
    
    private static func serialize(object: Any) throws -> String {
        let serializer = PLISTSerializer()
        return try serializer.serialize(object)
    }
}

public enum HttpResponseBody {
    
    case Json(AnyObject)
    case Xml(AnyObject)
    case Plist(AnyObject)
    case Html(String)
    case Text(String)
    case Custom(Serializer, Any)
    
    func data() -> [UInt8]? {
        do {
            switch self {
            case .Json(let object):
                let serialised = try JSONSerializer.serialize(object)
                return [UInt8](serialised.utf8)
            case .Xml(let object):
                let serialised = try XMLSerializer.serialize(object)
                return [UInt8](serialised.utf8)
            case .Plist(let object):
                let serialised = try PLISTSerializer.serialize(object)
                return [UInt8](serialised.utf8)
            case .Text(let body):
                let serialised = body
                return [UInt8](serialised.utf8)
            case .Html(let body):
                let serialised = "<html><meta charset=\"UTF-8\"><body>\(body)</body></html>"
                return [UInt8](serialised.utf8)
            case .Custom(let serializer, let object):
                let serialised = try serializer.serialize(object)
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
        case .OK(_)                 : return 200
        case .Created               : return 201
        case .Accepted              : return 202
        case .MovedPermanently      : return 301
        case .BadRequest            : return 400
        case .Unauthorized          : return 401
        case .Forbidden             : return 403
        case .NotFound              : return 404
        case .InternalServerError   : return 500
        case .RAW(let code, _ , _, _)   : return code
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
        case .RAW(_, let phrase, _, _) : return phrase
        }
    }
    
    func headers() -> [String: String] {
        var headers = [String:String]()
        headers["Server"] = "Swifter \(HttpServer.VERSION)"
        switch self {
		case .OK(let body):
            switch body {
                case .Json(_)   : headers["Content-Type"] = "application/json"
                case .Plist(_)  : headers["Content-Type"] = "application/xml"
                case .Xml(_)    : headers["Content-Type"] = "application/xml"
                // 'application/xml' or 'text/xml' ?
                // From RFC: http://www.rfc-editor.org/rfc/rfc3023.txt - "If an XML document -- that is, the unprocessed, 
                // source XML document -- is readable by casual users, text/xml is preferable to application/xml. 
                // MIME user agents (and web user agents) that do not have explicit support for text/xml will treat it as text/plain, 
                // for example, by displaying the XML MIME entity as plain text.
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
        case .OK(let body)          : return body.data()
        case .RAW(_, _, _, let data)  : return data
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



//
//  HttpHandlers+WebSockets.swift
//  Swifter
//
//  Copyright © 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

extension HttpHandlers {
    
    public class func websocket(message:(String) -> ()) -> (HttpRequest -> HttpResponse) {
        func closure(r: HttpRequest) -> HttpResponse {
            guard r.headers["upgrade"] == "websocket" else {
                return .BadRequest
            }
            guard r.headers["connection"] == "Upgrade" else {
                return .BadRequest
            }
            guard let secWebSocketKey = r.headers["sec-websocket-key"] else {
                return .BadRequest
            }
            let accept = (secWebSocketKey + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").SHA1()
            let acceptBASE64 = String(data: (accept.dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedDataWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength))!, encoding: NSUTF8StringEncoding)!;
            let upgradeHeaders = [ "Upgrade": "weboscket", "Connection": "Upgrade",
                "Sec-WebSocket-Accept": acceptBASE64
            ]
            return HttpResponse.RAW(101, "Switching Protocols", upgradeHeaders, nil)
        }
        return closure
    }

}
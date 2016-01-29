//
//  HttpHandlers+WebSockets.swift
//  Swifter
//
//  Copyright © 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

extension HttpHandlers {
    
    public class func websocket(handle:(String) -> ()) -> (HttpRequest -> HttpResponse) {
        return { r in
            guard r.headers["upgrade"] == "websocket" else {
                return .BadRequest
            }
            
            guard r.headers["connection"] == "Upgrade" else {
                return .BadRequest
            }
            guard let secWebSocketKey = r.headers["sec-websocket-key"] else {
                return .BadRequest
            }
            let accept = String.encodeToBase64((secWebSocketKey + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").SHA1())
            let upgradeHeaders = [ "Upgrade": "WebSocket", "Connection": "Upgrade", "Sec-WebSocket-Accept": accept]
            return HttpResponse.SwitchProtocols(upgradeHeaders) { socket  in
                let parser = WebSocketParser()
                while let frame = try? parser.readFrame(socket) {
                    handle(String.fromUInt8(frame.payload))
                }
            }
        }
    }
    
    public class WebSocketParser {
        
        enum Error: ErrorType {
            case UnknownOpCode(String)
        }
        
        public enum OpCode { case CONTINUE, CLOSE, PING, PONG, TEXT, BINARY }
        
        public class Frame {
            public var opcode = OpCode.CLOSE
            public var fin = false
            public var payload = [UInt8]()
        }
        
        public func readFrame(socket: Socket) throws -> Frame {
            let frm = Frame()
            let fst = try socket.read()
            frm.fin = fst & 0x80 != 0
            let opc = fst & 0x0F
            switch opc {
                case 0x00: frm.opcode = OpCode.CONTINUE
                case 0x01: frm.opcode = OpCode.TEXT
                case 0x02: frm.opcode = OpCode.BINARY
                case 0x08: frm.opcode = OpCode.CLOSE
                case 0x09: frm.opcode = OpCode.PING
                case 0x0A: frm.opcode = OpCode.PONG
                default  : throw Error.UnknownOpCode("\(opc)")
            }
            let sec = try socket.read()
            let msk = sec & 0x0F != 0
            var len = UInt64(sec & 0x7F)
            if len == 0x7E {1
                let b0 = UInt64(try socket.read())
                let b1 = UInt64(try socket.read())
                len = UInt64(littleEndian: b0 << 8 | b1)
            } else if len == 0x7F {
                let b0 = UInt64(try socket.read())
                let b1 = UInt64(try socket.read())
                let b2 = UInt64(try socket.read())
                let b3 = UInt64(try socket.read())
                let b4 = UInt64(try socket.read())
                let b5 = UInt64(try socket.read())
                let b6 = UInt64(try socket.read())
                let b7 = UInt64(try socket.read())
                len = UInt64(littleEndian: b0 << 54 | b1 << 48 | b2 << 40 | b3 << 32 | b4 << 24 | b5 << 16 | b6 << 8 | b7)
            }
            let mask = msk ? [try socket.read(), try socket.read(), try socket.read(), try socket.read()] : []
            for i in 0..<len {
                let byte = try socket.read()
                frm.payload.append(msk ? byte ^ mask[Int(i % 4)] : byte)
            }
            return frm
        }
    }
}
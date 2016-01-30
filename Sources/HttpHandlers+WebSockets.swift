//
//  HttpHandlers+WebSockets.swift
//  Swifter
//
//  Copyright © 2014-2016 Damian Kołakowski. All rights reserved.
//

import Foundation

extension HttpHandlers {
    
    public class func websocket(text:(String -> Void)?, _ binary:([UInt8] -> Void)?) -> (HttpRequest -> HttpResponse) {
        return { r in
            guard r.headers["upgrade"] == "websocket" else {
                return .BadRequest(.Text("Invalid value of 'Upgrade' header: \(r.headers["upgrade"])"))
            }
            guard r.headers["connection"] == "Upgrade" else {
                return .BadRequest(.Text("Invalid value of 'Connection' header: \(r.headers["connection"])"))
            }
            guard let secWebSocketKey = r.headers["sec-websocket-key"] else {
                return .BadRequest(.Text("Invalid value of 'Sec-Websocket-Key' header: \(r.headers["sec-websocket-key"])"))
            }
            let protocolSessionClosure: (Socket -> Void) = { socket in
                let session = WebSocketSession(socket)
                while let frame = try? session.readFrame(socket) {
                    switch frame.opcode {
                    case .TEXT:
                        if let handleText = text {
                            handleText(String.fromUInt8(frame.payload))
                        }
                    case .BINARY:
                        if let handleBinary = binary {
                            handleBinary(frame.payload)
                        }
                    default: break
                    }
                }
            }
            let secWebSocketAccept = String.encodeToBase64((secWebSocketKey + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").SHA1())
            let headers = [ "Upgrade": "WebSocket", "Connection": "Upgrade", "Sec-WebSocket-Accept": secWebSocketAccept]
            return HttpResponse.SwitchProtocols(headers, protocolSessionClosure)
        }
    }
    
    public class WebSocketSession {
        
        public enum Error: ErrorType { case UnknownOpCode(String), UnMaskedFrame }
        
        public enum OpCode { case CONTINUE, CLOSE, PING, PONG, TEXT, BINARY }
        
        public class Frame {
            public var opcode = OpCode.CLOSE
            public var fin = false
            public var payload = [UInt8]()
        }

        private let socket: Socket
        
        init(_ socket: Socket) {
            self.socket = socket
        }
        
        public func writeText(text: String) -> Void {
            let finAndOpCode = encodeFinAndOpCode(true, op: OpCode.TEXT)
            let maskAndLngth = encodeLengthAndMaskFlag(UInt64(text.utf8.count), false)
            do {
                try socket.writeUInt8([finAndOpCode])
                try socket.writeUInt8(maskAndLngth)
                try socket.writeUInt8([UInt8](text.utf8))
            } catch {
                print(error)
            }
        }
    
        public func writeBinary(binary: [UInt8]) -> Void {
            let finAndOpCode = encodeFinAndOpCode(true, op: OpCode.BINARY)
            let maskAndLngth = encodeLengthAndMaskFlag(UInt64(binary.count), false)
            do {
                try self.socket.writeUInt8([finAndOpCode])
                try self.socket.writeUInt8(maskAndLngth)
                try self.socket.writeUInt8(binary)
            } catch {
                print(error)
            }
        }
        
        private func encodeFinAndOpCode(fin: Bool, op: OpCode) -> UInt8 {
            var b = UInt8(fin ? 0x80 : 0x00);
            switch op {
            case .CONTINUE : b |= 0x00 & 0x0F;
            case .TEXT     : b |= 0x01 & 0x0F;
            case .BINARY   : b |= 0x02 & 0x0F;
            case .CLOSE    : b |= 0x08 & 0x0F;
            case .PING     : b |= 0x09 & 0x0F;
            case .PONG     : b |= 0x0A & 0x0F;
            }
            return b
        }
        
        private func encodeLengthAndMaskFlag(len: UInt64, _ masked: Bool) -> [UInt8] {
            let b: UInt8 = masked ? 0x80 : 0x00;
            var buffer = [UInt8]()
            if (len > 0xFF_FF) {
                buffer.append(b | 0x7F);
                buffer.append(UInt8(len >> 56) & 0xFF);
                buffer.append(UInt8(len >> 48) & 0xFF);
                buffer.append(UInt8(len >> 40) & 0xFF);
                buffer.append(UInt8(len >> 32) & 0xFF);
                buffer.append(UInt8(len >> 24) & 0xFF);
                buffer.append(UInt8(len >> 16) & 0xFF);
                buffer.append(UInt8(len >> 8 ) & 0xFF);
                buffer.append(UInt8(len & 0xFF));
            } else if (len >= 0x7E) {
                buffer.append(b | 0x7E);
                buffer.append(UInt8(len >> 8));
                buffer.append(UInt8(len & 0xFF));
            } else {
                buffer.append(b | UInt8(len));
            }
            return buffer
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
                // "If an unknown opcode is received, the receiving endpoint MUST _Fail the WebSocket Connection_."
                // http://tools.ietf.org/html/rfc6455#section-5.2 ( Page 29 )
                default  : throw Error.UnknownOpCode("\(opc)")
            }
            let sec = try socket.read()
            let msk = sec & 0x0F != 0
            guard msk else {
                // "...a client MUST mask all frames that it sends to the serve.."
                // http://tools.ietf.org/html/rfc6455#section-5.1
                throw Error.UnMaskedFrame
            }
            var len = UInt64(sec & 0x7F)
            if len == 0x7E {
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
            let mask = [try socket.read(), try socket.read(), try socket.read(), try socket.read()]
            for i in 0..<len {
                frm.payload.append(try socket.read() ^ mask[Int(i % 4)])
            }
            return frm
        }
    }
}
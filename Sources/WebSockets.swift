//
//  HttpHandlers+WebSockets.swift
//  Swifter
//
//  Copyright © 2014-2016 Damian Kołakowski. All rights reserved.
//

#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

public func websocket(
        text: ((WebSocketSession, String) -> Void)?,
    _ binary: ((WebSocketSession, [UInt8]) -> Void)?) -> (HttpRequest -> HttpResponse) {
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
            while let frame = try? session.readFrame() {
                switch frame.opcode {
                case .Text:
                    if let handleText = text {
                        handleText(session, String.fromUInt8(frame.payload))
                    }
                case .Binary:
                    if let handleBinary = binary {
                        handleBinary(session, frame.payload)
                    }
                default: break
                }
            }
        }
        let secWebSocketAccept = String.toBase64((secWebSocketKey + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").SHA1())
        let headers = [ "Upgrade": "WebSocket", "Connection": "Upgrade", "Sec-WebSocket-Accept": secWebSocketAccept]
        return HttpResponse.SwitchProtocols(headers, protocolSessionClosure)
    }
}

public class WebSocketSession {
    
    public enum Error: ErrorType { case UnknownOpCode(String), UnMaskedFrame }
    public enum OpCode { case Continue, Close, Ping, Pong, Text, Binary }
    
    public class Frame {
        public var opcode = OpCode.Close
        public var fin = false
        public var payload = [UInt8]()
    }

    private let socket: Socket
    
    public init(_ socket: Socket) {
        self.socket = socket
    }
    
    public func writeText(text: String) -> Void {
        self.writeFrame(ArraySlice(text.utf8), OpCode.Text)
    }

    public func writeBinary(binary: [UInt8]) -> Void {
        self.writeBinary(ArraySlice(binary))
    }
    
    public func writeBinary(binary: ArraySlice<UInt8>) -> Void {
        self.writeFrame(binary, OpCode.Binary)
    }
    
    private func writeFrame(data: ArraySlice<UInt8>, _ op: OpCode, _ fin: Bool = true) {
        let finAndOpCode = encodeFinAndOpCode(fin, op: op)
        let maskAndLngth = encodeLengthAndMaskFlag(UInt64(data.count), false)
        do {
            try self.socket.writeUInt8([finAndOpCode])
            try self.socket.writeUInt8(maskAndLngth)
            try self.socket.writeUInt8(data)
        } catch {
            print(error)
        }
    }
    
    private func encodeFinAndOpCode(fin: Bool, op: OpCode) -> UInt8 {
        var encodedByte = UInt8(fin ? 0x80 : 0x00);
        switch op {
        case .Continue : encodedByte |= 0x00 & 0x0F;
        case .Text     : encodedByte |= 0x01 & 0x0F;
        case .Binary   : encodedByte |= 0x02 & 0x0F;
        case .Close    : encodedByte |= 0x08 & 0x0F;
        case .Ping     : encodedByte |= 0x09 & 0x0F;
        case .Pong     : encodedByte |= 0x0A & 0x0F;
        }
        return encodedByte
    }
    
    private func encodeLengthAndMaskFlag(len: UInt64, _ masked: Bool) -> [UInt8] {
        let encodedLngth = UInt8(masked ? 0x80 : 0x00)
        var encodedBytes = [UInt8]()
        switch len {
        case 0...125:
            encodedBytes.append(encodedLngth | UInt8(len));
        case 126...UInt64(UINT16_MAX):
            encodedBytes.append(encodedLngth | 0x7E);
            encodedBytes.append(UInt8(len >> 8));
            encodedBytes.append(UInt8(len & 0xFF));
        default:
            encodedBytes.append(encodedLngth | 0x7F);
            encodedBytes.append(UInt8(len >> 56) & 0xFF);
            encodedBytes.append(UInt8(len >> 48) & 0xFF);
            encodedBytes.append(UInt8(len >> 40) & 0xFF);
            encodedBytes.append(UInt8(len >> 32) & 0xFF);
            encodedBytes.append(UInt8(len >> 24) & 0xFF);
            encodedBytes.append(UInt8(len >> 16) & 0xFF);
            encodedBytes.append(UInt8(len >> 08) & 0xFF);
            encodedBytes.append(UInt8(len >> 00) & 0xFF);
        }
        return encodedBytes
    }
    
    public func readFrame() throws -> Frame {
        let frm = Frame()
        let fst = try socket.read()
        frm.fin = fst & 0x80 != 0
        let opc = fst & 0x0F
        switch opc {
            case 0x00: frm.opcode = OpCode.Continue
            case 0x01: frm.opcode = OpCode.Text
            case 0x02: frm.opcode = OpCode.Binary
            case 0x08: frm.opcode = OpCode.Close
            case 0x09: frm.opcode = OpCode.Ping
            case 0x0A: frm.opcode = OpCode.Pong
            // "If an unknown opcode is received, the receiving endpoint MUST _Fail the WebSocket Connection_."
            // http://tools.ietf.org/html/rfc6455#section-5.2 ( Page 29 )
            default  : throw Error.UnknownOpCode("\(opc)")
        }
        let sec = try socket.read()
        let msk = sec & 0x80 != 0
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

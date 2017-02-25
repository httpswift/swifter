//
//  WebSockets.swift
//  Swifter
//
//  Copyright © 2016 Damian Kolakowski. All rights reserved.
//
import Foundation

public enum WebSocketError: Error {
    case unknownOpCode(String)
    case unMaskedFrame
    case notImplemented(String)
}

public enum WebsocketEvent {
    case disconnected(Int, String)
    case text(String)
    case binary([UInt8])
}

public class WebsocketResponse: Response {
    
    public init(_ request: Request, _ closure: @escaping ((WebsocketEvent) -> Void)) {
        
        super.init()
            
        guard request.hasToken("websocket", forHeader: "upgrade") else {
            self.status = Status.badRequest.rawValue
            self.body = [UInt8](("Invalid value of 'Upgrade' header.").utf8)
            return
        }
        
        guard request.hasToken("upgrade", forHeader: "connection") else {
            self.status = Status.badRequest.rawValue
            self.body = [UInt8](("Invalid value of 'Connection' header.").utf8)
            return
        }
        
        guard let (_, secWebSocketKey) = request.headers.filter({ $0.0 == "sec-websocket-key" }).first else {
            self.status = Status.badRequest.rawValue
            self.body = [UInt8](("Invalid value of 'Sec-Websocket-Key' header.").utf8)
            return
        }
        
        guard let secWebSocketAccept = String.toBase64((secWebSocketKey + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").sha1()) else {
            self.status = Status.internalServerError.rawValue
            self.body = [UInt8](("Failed to convert websocket key value to base64.").utf8)
            return
        }
        
        self.status = Status.switchingProtocols.rawValue
        
        self.headers = [ ("Upgrade", "WebSocket"), ("Connection", "Upgrade"), ("Sec-WebSocket-Accept", secWebSocketAccept)]
        
        self.processingSuccesor = WebsocketDataPorcessor(WebsocketFramesProcessor(closure))
    }
    
    public required init(integerLiteral value: Int) {
        fatalError("init(integerLiteral:) has not been implemented")
    }
}

public class WebSocketFrame {
    
    public enum OpCode: UInt8 {
        case `continue` = 0x00
        case close = 0x08
        case ping = 0x09
        case pong = 0x0A
        case text = 0x01
        case binary = 0x02
    }
    
    public init(_ opcode: OpCode, _ payload: [UInt8]) {
        self.opcode = opcode
        self.payload = payload
    }
    
    public let opcode: OpCode
    public let payload: [UInt8]
}

public class WebsocketFramesProcessor {
    
    private let closure: ((WebsocketEvent) -> Void)
    
    public init(_ closure: @escaping ((WebsocketEvent) -> Void)) {
        self.closure = closure
    }
    
    public func process(_ frame: WebSocketFrame) throws {
        switch frame.opcode {
        case .text:
            if let text = String(bytes: frame.payload, encoding: .utf8) {
                self.closure(.text(text))
            } else {
                print("Invalid payload (not utf8): \(frame.payload)")
            }
        case .binary:
            self.closure(.binary(frame.payload))
        default:
            throw WebSocketError.notImplemented("Not able to handle: \(frame.opcode.rawValue)")
        }
    }
}

public class WebsocketDataPorcessor: IncomingDataProcessor {
    
    private let framesProcessor: WebsocketFramesProcessor
    
    public init(_ framesProcessor: WebsocketFramesProcessor) {
        self.framesProcessor = framesProcessor
    }
    
    private var stack = [UInt8]()
    
    public func process(_ chunk: ArraySlice<UInt8>) throws {
        
        stack.append(contentsOf: chunk)
        
        guard stack.count > 1 else { return }
        
        _ = stack[0] & 0x80 != 0
        let opc = stack[0] & 0x0F
        
        guard let opcode = WebSocketFrame.OpCode(rawValue: opc) else {
            // "If an unknown opcode is received, the receiving endpoint MUST _Fail the WebSocket Connection_."
            // http://tools.ietf.org/html/rfc6455#section-5.2 ( Page 29 )
            throw WebSocketError.unknownOpCode("\(opc)")
        }
        
        let msk = stack[1] & 0x80 != 0
        
        guard msk else {
            // "...a client MUST mask all frames that it sends to the serve.."
            // http://tools.ietf.org/html/rfc6455#section-5.1
            throw WebSocketError.unMaskedFrame
        }
        
        var len = UInt64(stack[1] & 0x7F)
        var offset = 2
        if len == 0x7E {
            guard stack.count > 3 else { return }
            let b0 = UInt64(stack[2])
            let b1 = UInt64(stack[3])
            len = UInt64(littleEndian: b0 << 8 | b1)
            offset = 4
        } else if len == 0x7F {
            guard stack.count > 9 else { return }
            let b0 = UInt64(stack[2])
            let b1 = UInt64(stack[3])
            let b2 = UInt64(stack[4])
            let b3 = UInt64(stack[5])
            let b4 = UInt64(stack[6])
            let b5 = UInt64(stack[7])
            let b6 = UInt64(stack[8])
            let b7 = UInt64(stack[9])
            len = UInt64(littleEndian: b0 << 54 | b1 << 48 | b2 << 40 | b3 << 32 | b4 << 24 | b5 << 16 | b6 << 8 | b7)
            offset = 10
        }
        
        guard (len + UInt64(offset) + 4) >= UInt64(stack.count) else {
            return
        }
        
        let mask = [stack[offset], stack[offset+1], stack[offset+2], stack[offset+3]]
        
        offset = offset + mask.count
        
        let payload = stack[offset..<(offset + Int(len /* //TODO fix this */))].enumerated().map { $0.element ^ mask[Int($0.offset % 4)] }
        
        stack.removeFirst(offset+Int(len))
        
        try framesProcessor.process(WebSocketFrame(opcode, payload))
    }
}

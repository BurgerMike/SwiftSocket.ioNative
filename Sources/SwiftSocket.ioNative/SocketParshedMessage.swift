//
//  SocketMessageParser.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 08/05/25.
//

import Foundation

public struct SocketParsedMessage {
    public enum MessageType: Int {
        case connect = 40
        case disconnect = 41
        case event = 42
        case ack = 43
        case error = 44
        case unknown = -1
    }

    public let type: MessageType
    public let event: String?
    public let data: CodableValue?
    public let raw: String
}

public struct SocketMessageParser {
    public static func parse(_ raw: String) -> SocketParsedMessage? {
        guard let code = Int(raw.prefix(2)),
              let type = SocketParsedMessage.MessageType(rawValue: code) else {
            return SocketParsedMessage(type: .unknown, event: nil, data: nil, raw: raw)
        }

        switch type {
        case .event:
            return parseEvent(raw, type: type)
        case .connect, .disconnect, .ack, .error:
            return SocketParsedMessage(type: type, event: nil, data: nil, raw: raw)
        default:
            return nil
        }
    }

    private static func parseEvent(_ raw: String, type: SocketParsedMessage.MessageType) -> SocketParsedMessage? {
        guard let index = raw.firstIndex(of: "[") else {
            return SocketParsedMessage(type: .event, event: nil, data: nil, raw: raw)
        }

        let payload = String(raw[index...])
        guard let jsonData = payload.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: jsonData) as? [Any],
              let event = array.first as? String else {
            return SocketParsedMessage(type: .event, event: nil, data: nil, raw: raw)
        }

        let content = array.dropFirst().first
        var wrappedData: Data? = nil
        if let content = content {
            wrappedData = try? JSONSerialization.data(withJSONObject: content)
        }

        let decoded = try? JSONDecoder().decode(CodableValue.self, from: wrappedData ?? Data())

        return SocketParsedMessage(type: type, event: event, data: decoded, raw: raw)
    }
}

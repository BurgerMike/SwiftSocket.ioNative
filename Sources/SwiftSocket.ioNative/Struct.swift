import Foundation

/// Representa un mensaje tipo socket.io estilo `42["event", {...}]`
public struct SocketMessage: Codable, CustomStringConvertible {
    public let event: String
    public let data: CodableValue
    
    private static let eventPrefix = "42"

    public init(event: String, data: CodableValue) {
        self.event = event
        self.data = data
    }

    public func encodedString() throws -> String {
        let wrapper: [CodableValue] = [.string(event), data]
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(wrapper)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw SocketError.encodingFailed(reason: "Could not convert to string")
        }
        return Self.eventPrefix + jsonString
    }

    public static func decode(from text: String) throws -> SocketMessage {
        switch true {
        case text == "40":
            // Evento especial: conexión establecida (único al conectarse)
            return SocketMessage(event: "__connected", data: .null)
        case text == "41":
            // Evento especial: desconexión (único al cerrarse)
            return SocketMessage(event: "__disconnected", data: .null)
        case text == "3":
            // Evento especial: pong de latido (heartbeat)
            return SocketMessage(event: "__pong", data: .null)
        case text.hasPrefix(eventPrefix):
            let jsonPart = String(text.dropFirst(eventPrefix.count))
            let decoder = JSONDecoder()
            let decoded = try decoder.decode([CodableValue].self, from: Data(jsonPart.utf8))

            guard decoded.count == 2,
                  case let .string(event) = decoded[0] else {
                throw SocketError.decodingFailed(event: "unknown", reason: "Message event could not be decoded")
            }

            let payload = decoded[1]
            return SocketMessage(event: event, data: payload)

        default:
            throw SocketError.decodingFailed(event: "unknown", reason: "Unknown or unsupported prefix")
        }
    }

    public var description: String {
        return "📨 SocketMessage(event: \(event), data: \(data))"
    }
}

/// Payload de un mensaje de chat simple
public struct ChatMessage: Codable {
    public let groupId: Int
    public let content: String

    public init(groupId: Int, content: String) {
        self.groupId = groupId
        self.content = content
    }
}

/// Contenedor genérico para enviar evento tipo socket.io
public struct EmitMessage<T: Codable>: Codable {
    public let event: String
    public let data: T

    public init(event: String, data: T) {
        self.event = event
        self.data = data
    }
}

/// Representación dinámica de valores Codable tipo JSON
public enum CodableValue: Codable {
    case dictionary([String: CodableValue])
    case array([CodableValue])
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([String: CodableValue].self) {
            self = .dictionary(value)
        } else if let value = try? container.decode([CodableValue].self) {
            self = .array(value)
        } else {
            self = .null
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .dictionary(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

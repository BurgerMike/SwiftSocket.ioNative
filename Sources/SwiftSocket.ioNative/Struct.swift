import Foundation

/// Representa un mensaje tipo socket.io estilo `42["event", {...}]`
public struct SocketMessage: Codable, CustomStringConvertible {
    public let event: String
    public let data: CodableValue
    
    private static let parserPrefix = "42"

    public init(event: String, data: CodableValue) {
        self.event = event
        self.data = data
    }

    public func encodedString() throws -> String {
        let wrapper: [CodableValue] = [.string(event), data]
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(wrapper)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw SocketError.encodingFailed(reason: "No se pudo convertir a string")
        }
        return Self.parserPrefix + jsonString
    }

    public static func decode(from text: String) throws -> SocketMessage {
        guard text.hasPrefix(parserPrefix) else {
            throw SocketError.decodingFailed(event: "unknown", reason: "No comienza con el prefijo esperado")
        }

        let jsonPart = String(text.dropFirst(parserPrefix.count))
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([CodableValue].self, from: Data(jsonPart.utf8))

        guard decoded.count == 2,
              case let .string(event) = decoded[0] else {
            throw SocketError.decodingFailed(event: "unknown", reason: "No se pudo decodificar el evento del mensaje")
        }

        let payload = decoded[1]
        return SocketMessage(event: event, data: payload)
    }

    public var description: String {
        return "📨 SocketMessage(event: \(event), data: \(data))"
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

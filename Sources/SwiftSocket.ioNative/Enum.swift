//
//  Enum.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 15/05/25.
//
import Foundation

/// Enum que representa errores comunes en el sistema de sockets.
public enum SocketError: Error, Equatable {
    case connectionFailed(reason: String)
    case encodingFailed
    case decodingFailed
    case unknown
}

/// Un tipo codificable que representa valores JSON dinámicos.
/// Permite serializar/deserializar valores arbitrarios para sockets.
public enum CodableValue: Codable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case dictionary([String: CodableValue])
    case array([CodableValue])
    case null

    // MARK: - Decodificador (Decodable)
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: CodableValue].self) {
            self = .dictionary(value)
        } else if let value = try? container.decode([CodableValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Tipo no compatible para CodableValue"
            )
        }
    }

    // MARK: - Codificador (Encodable)
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

    // MARK: - Decodificar a modelo específico
    public func decode<T: Decodable>(as type: T.Type) -> T? {
        guard case .dictionary(let dict) = self,
              let data = try? JSONEncoder().encode(dict) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Codificar desde modelo específico
    public static func encode<T: Encodable>(from value: T) -> CodableValue? {
        do {
            let data = try JSONEncoder().encode(value)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            return fromAny(jsonObject)
        } catch {
            return nil
        }
    }

    // MARK: - Conversión interna desde Any
    private static func fromAny(_ any: Any) -> CodableValue {
        switch any {
        case let value as String:
            return .string(value)
        case let value as Int:
            return .int(value)
        case let value as Double:
            return .double(value)
        case let value as Bool:
            return .bool(value)
        case let value as [String: Any]:
            let dict = value.mapValues { fromAny($0) }
            return .dictionary(dict)
        case let value as [Any]:
            let array = value.map { fromAny($0) }
            return .array(array)
        default:
            return .null
        }
    }
}

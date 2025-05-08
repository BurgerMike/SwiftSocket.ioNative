//
//  Utilitys.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 07/05/25.
//

import Foundation

public enum SocketUtils {

    /// Codifica un valor codificable a JSON Data
    public static func encodeToJSON<T: Codable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    /// Decodifica un JSON Data a un tipo decodificable
    public static func decodeFromJSON<T: Codable>(_ type: T.Type, from data: Data) -> T? {
        try? JSONDecoder().decode(type, from: data)
    }

    /// Devuelve la fecha ISO8601 actual como String
    public static func currentISO8601Timestamp() -> String {
        ISO8601DateFormatter().string(from: Date())
    }

    /// Imprime un log solo en modo debug
    public static func debugLog(_ message: @autoclosure () -> String) {
    #if DEBUG
        print("🧩", message())
    #endif
    }
}

// MARK: - CodableValue extension for JSON encoding

public extension CodableValue {
    /// Codifica el `CodableValue` en una cadena JSON
    func encodedJSONString() throws -> String {
        let encoder = JSONEncoder()
        let data = try encoder.encode(self)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "CodableValue", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No se pudo convertir el JSON a String"
            ])
        }
        return jsonString
    }
}

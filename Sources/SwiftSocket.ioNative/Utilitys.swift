//
//  Utilitys.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 07/05/25.
//


import Foundation

/// Codifica un valor codificable a JSON Data
public func encodeToJSON<T: Encodable>(_ value: T) -> Data? {
    try? JSONEncoder().encode(value)
}

/// Decodifica un JSON Data a un tipo decodificable
public func decodeFromJSON<T: Decodable>(_ type: T.Type, from data: Data) -> T? {
    try? JSONDecoder().decode(T.self, from: data)
}

/// Devuelve la fecha ISO8601 actual como String
public func currentISO8601Timestamp() -> String {
    ISO8601DateFormatter().string(from: Date())
}

/// Imprime un log solo en modo debug
public func debugLog(_ message: @autoclosure () -> String) {
#if DEBUG
    print("🧩", message())
#endif
}

//
//  SocketEvent.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 13/05/25.
//
import Foundation

public struct SocketEvent: Codable {
    public let event: String
    public let data: Data?

    // ✅ Corrección: Solo requiere Encodable para emitir
    public init<T: Encodable>(event: String, data: T?) {
        self.event = event
        self.data = try? JSONEncoder().encode(data)
    }

    // ✅ Utilidad para decodificar la data si se espera respuesta del servidor
    public func decodedData<T: Decodable>(as type: T.Type) -> T? {
        guard let data = data else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

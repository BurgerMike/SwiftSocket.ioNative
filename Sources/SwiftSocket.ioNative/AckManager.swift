//
//  AckManager.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 07/05/25.
//
import Foundation
import SwiftUI

/// Encargado de manejar los callbacks de ack asociados a mensajes emitidos
public actor AckManager {
    public static let shared = AckManager()

    private var ackHandlers: [Int: (CodableValue) -> Void] = [:]
    private var currentId: Int = 0

    private init() {}

    /// Genera un nuevo ID y registra el handler para cuando llegue la respuesta
    public func register(handler: @escaping (CodableValue) -> Void) -> Int {
        currentId += 1
        ackHandlers[currentId] = handler
        return currentId
    }

    /// Ejecuta y elimina el handler asociado al ackId recibido
    public func handleAck(id: Int, value: CodableValue) {
        if let handler = ackHandlers[id] {
            handler(value)
            ackHandlers.removeValue(forKey: id)
        }
    }

    /// Limpia todos los handlers pendientes (por ejemplo, tras desconexión)
    public func reset() {
        ackHandlers.removeAll()
        currentId = 0
    }
}

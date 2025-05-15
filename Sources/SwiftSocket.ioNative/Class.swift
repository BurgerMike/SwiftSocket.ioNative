//
//  Class.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 14/05/25.
//
import Foundation


/// Administra los callbacks `ack` de eventos emitidos que esperan respuesta del servidor.
final class AckManager {
    private var acks: [String: (Any?) -> Void] = [:]
    private let queue = DispatchQueue(label: "AckManagerQueue", attributes: .concurrent)
    
    /// Registra un callback para un ID específico.
    func storeAck(id: String, callback: @escaping (Any?) -> Void) {
        queue.async(flags: .barrier) {
            self.acks[id] = callback
        }
    }
    
    /// Resuelve un ack cuando el servidor responde con un evento que incluye ese ID.
    func resolveAck(id: String, with response: Any?) {
        queue.async(flags: .barrier) {
            if let callback = self.acks.removeValue(forKey: id) {
                DispatchQueue.main.async {
                    callback(response)
                }
            }
        }
    }
    
    /// Limpia todos los acks pendientes (por desconexión, error, etc.)
    func reset() {
        queue.async(flags: .barrier) {
            self.acks.removeAll()
        }
    }
}

// Sources/SwiftSocketIONative/EventRouter.swift

@MainActor
final class EventRouter {
    private var listeners: [String: [(CodableValue?) -> Void]] = [:]

    init() {}

    /// Registra un callback para un evento específico.
    func on(_ event: String, callback: @escaping (CodableValue?) -> Void) {
        listeners[event, default: []].append(callback)
    }

    /// Elimina todos los callbacks para un evento específico.
    func off(_ event: String) {
        listeners.removeValue(forKey: event)
    }

    /// Ejecuta todos los callbacks registrados para el evento recibido.
    func handle(event: SocketEvent) {
        guard let callbacks = listeners[event.event] else { return }

        for callback in callbacks {
            callback(event.payload)
        }
    }

    /// Limpia todos los eventos registrados (opcional, por reconexión, logout, etc.).
    func clearAll() {
        listeners.removeAll()
    }
}

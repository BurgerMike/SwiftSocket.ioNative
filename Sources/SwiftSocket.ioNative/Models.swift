//
//  Struct.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 14/05/25.
//
import Foundation

// Ejemplo de implementación de un mensaje recibido
public struct ChatMessage: MessageReceivable {
    public let messageId: String
    public let content: String
    public let senderId: String
    public let timestamp: Date

    public init(messageId: String, content: String, senderId: String, timestamp: Date) {
        self.messageId = messageId
        self.content = content
        self.senderId = senderId
        self.timestamp = timestamp
    }
}


/// Ejemplo de implementación de un mensaje a enviar
public struct OutgoingMessage: MessageSendable {
    public let content: String
    public let recipientId: String

    public init(content: String, recipientId: String) {
        self.content = content
        self.recipientId = recipientId
    }
}


/// Representa un evento enviado o recibido por el cliente socket.
/// Pensado para ser flexible, completo y extensible.
public struct SocketEvent: Codable {
    /// Nombre del evento (`"sendMessage"`, `"typing"`, etc.).
    public let event: String

    /// Cuerpo del evento (mensaje, comandos, etc.).
    public let payload: CodableValue?

    /// ID del evento para rastrear ACKs (opcional).
    public let id: String?

    /// Fecha y hora del evento (opcional).
    public let timestamp: Date?

    /// ID del usuario que emitió el evento (opcional).
    public let senderId: String?

    /// Metadatos opcionales (customizable por el cliente o el servidor).
    public let meta: [String: CodableValue]?

    public init(
        event: String,
        payload: CodableValue? = nil,
        id: String? = nil,
        timestamp: Date? = nil,
        senderId: String? = nil,
        meta: [String: CodableValue]? = nil
    ) {
        self.event = event
        self.payload = payload
        self.id = id
        self.timestamp = timestamp
        self.senderId = senderId
        self.meta = meta
    }
}
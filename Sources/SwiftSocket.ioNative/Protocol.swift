//
//  Protocol.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 14/05/25.
//
import Foundation

// MARK: - Protocolo principal del cliente Socket

/// Define las funciones básicas para conectarse a un servidor WebSocket tipo socket.io.
public protocol SocketClient {
    /// Conecta el socket al servidor.
    func connect()

    /// Cierra la conexión con el servidor.
    func disconnect()

    /// Envía un evento al servidor con datos opcionales y soporte para ACK.
    func emit(event: String, data: Encodable?, ack: ((Any?) -> Void)?)

    /// Escucha un evento específico desde el servidor.
    func on(event: String, callback: @escaping (Any) -> Void)

    /// Elimina todos los listeners de un evento específico.
    func off(event: String)
}

// MARK: - Protocolo para manejar errores

/// Permite al cliente notificar errores personalizados a quien lo use.
public protocol SocketErrorHandler: AnyObject {
    func socketDidCatchError(_ error: SocketError)
}

// MARK: - Errores definidos para el sistema de sockets



// MARK: - Protocolo de recepción de mensajes

/// Define la estructura que debe tener un mensaje recibido en el chat.
public protocol MessageReceivable: Codable {
    var messageId: String { get }
    var content: String { get }
    var senderId: String { get }
    var timestamp: Date { get }
}



// MARK: - Protocolo de envío de mensajes

/// Define la estructura mínima que debe tener un mensaje a enviar.
public protocol MessageSendable: Encodable {
    var content: String { get }
    var recipientId: String { get }
}
//
//  Protocolos.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 04/05/25.
//

import Foundation

/// Delegado para eventos del socket como conexión, desconexión, mensajes y errores
public protocol SocketConnectionDelegate: AnyObject {
    func socketDidConnect()
    func socketDidDisconnect(error: Error?)
    func socketDidReceive(event: String, data: Data)
    func socketDidCatchError(_ error: Error)
    func socketDidReceivePong()
}

/// Protocolo que define cómo emitir eventos personalizados (tipo socket.emit)
public protocol SocketEventEmitter {
    func emit(event: SocketUserEvent, data: CodableValue)
}

/// Protocolo que define cómo registrar listeners para eventos personalizados (tipo socket.on)
public protocol SocketEventListener {
    func on(event: SocketUserEvent, callback: @escaping (CodableValue) -> Void)
}

/// Protocolo para manejo explícito de errores internos del socket
public protocol SocketErrorHandler: AnyObject {
    func socketDidCatchError(_ error: SocketError)
}

/// Protocolo base que define las operaciones estándar de un cliente socket compatible con socket.io
public protocol NativeSocketClient {
    func connect(with userId: String?)
    func disconnect()
    func emit(event: SocketUserEvent, data: CodableValue)
    func on(event: SocketUserEvent, callback: @escaping (CodableValue) -> Void)
    func off(event: String)
    var onEvent: ((SocketConnectionEvent) -> Void)? { get set }
    var isConnected: Bool { get }
}

/// Protocolo combinado que unifica todas las capacidades del cliente de socket (emitir, escuchar, manejar errores)
public typealias FullSocketClient = NativeSocketClient & SocketEventEmitter & SocketEventListener & SocketErrorHandler

/// Errores posibles que puede emitir el cliente socket
public enum SocketError: Error {
    case encodingFailed(reason: String)
    case decodingFailed(event: String, reason: String)
    case connectionFailed(reason: String)
}


public enum SocketConnectionEvent: Equatable, CustomStringConvertible, Codable {
    case connected
    case disconnected
    case connectionError(String)
    case pongReceived
    
    public var description: String {
        switch self {
        case .connected: return "✅ Connected"
        case .disconnected: return "🔌 Disconnected"
        case .pongReceived: return "💓 Pong Received"
        case .connectionError(let reason): return "❌ Connection Error: \(reason)"
        }
    }
}

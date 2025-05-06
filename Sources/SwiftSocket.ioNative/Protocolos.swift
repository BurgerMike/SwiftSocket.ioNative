//
//  Protocolos.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 04/05/25.
//

import Foundation

/// Delegado para eventos del socket como conexión, desconexión o errores
public protocol SocketConnectionDelegate: AnyObject {
    func socketDidConnect()
    func socketDidDisconnect(error: Error?)
    func socketDidReceiveError(_ error: SocketError)
    func socketDidReceivePong()
}

/// Protocolo que define cómo emitir eventos personalizados
public protocol SocketEventEmitter {
    func emit(event: SocketUserEvent, data: CodableValue)
}

/// Protocolo que define cómo registrar eventos
public protocol SocketEventListener {
    func on(event: SocketUserEvent, callback: @escaping (CodableValue) -> Void)
}

/// Errores posibles que puede emitir el cliente socket
public enum SocketError: Error {
    case encodingFailed(reason: String)
    case decodingFailed(event: String, reason: String)
    case connectionFailed(reason: String)
}

/// Protocolo para manejar errores desde el cliente socket
public protocol SocketErrorHandler: AnyObject {
    func socketDidCatchError(_ error: SocketError)
}

/// Protocolo base que define las operaciones estándar de un cliente de socket
public protocol NativeSocketClient {
    func connect(with userId: String?)
    func disconnect()
    func emit(event: SocketUserEvent, data: CodableValue)
    func on(event: SocketUserEvent, callback: @escaping (CodableValue) -> Void)
    func off(event: String)
    var onEvent: ((SocketConnectionEvent) -> Void)? { get set }
    var isConnected: Bool { get }
}

/// Protocolo combinado que unifica todas las capacidades del cliente de socket
public typealias FullSocketClient = NativeSocketClient & SocketEventEmitter & SocketEventListener & SocketErrorHandler

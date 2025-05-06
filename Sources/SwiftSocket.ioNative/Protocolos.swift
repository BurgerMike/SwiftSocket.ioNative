//
//  Protocolos.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 04/05/25.
//


import Foundation

public protocol SocketErrorHandler: AnyObject {
    func socketDidCatchError(_ error: SocketIOError)
}

public protocol NativeSocketClient {
    var isConnected: Bool { get }
    var pendingUserId: String? { get set }
    func connect()
    func disconnect()
    func emit<T: Encodable>(event: String, data: T)
    func on<T: Decodable>(event: String, callback: @escaping (T) -> Void)
    func off(event: String)
    func authenticate(with userId: String)
    var onConnect: (() -> Void)? { get set }
    var onDisconnect: ((Error?) -> Void)? { get set }
    var errorDelegate: SocketErrorHandler? { get set }
    init(baseURL: URL, path: String, queryItems: [URLQueryItem])
}

public protocol SocketPayload: Encodable {
    var eventName: String { get }
}

public protocol SocketReceivable: SocketPayload {}
public protocol SocketEmittable: SocketPayload {}

public protocol SocketIOCodablePacket {
    var code: Int { get }
    var description: String { get }
    init?(rawCode: Int)
}

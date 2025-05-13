//
//  Protocols.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 13/05/25.
//

import Foundation

public protocol SocketClient {
    func connect()
    func disconnect()
    func emit<T: Encodable>(event: String, data: T?, ack: ((Any?) -> Void)?)
    func on(event: String, callback: @escaping (Any) -> Void)
    func off(event: String)
}

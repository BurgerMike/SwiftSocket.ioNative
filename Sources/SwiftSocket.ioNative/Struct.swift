//
//  Struct.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 04/05/25.
//


import SwiftUI


public struct SocketEvent<T: Codable>: Codable, SocketReceivable {
    public let name: String
    public let payload: T

    public init(name: String, payload: T) {
        self.name = name
        self.payload = payload
    }

    public var eventName: String { name }
}

public struct SocketHandshake: Codable {
    public let sid: String
    public let pingInterval: Int
    public let pingTimeout: Int

    public init(sid: String, pingInterval: Int, pingTimeout: Int) {
        self.sid = sid
        self.pingInterval = pingInterval
        self.pingTimeout = pingTimeout
    }
}

public struct SocketEmitPayload<T: Encodable>: Encodable, SocketEmittable {
    public let event: String
    public let data: T?

    public init(event: String, data: T?) {
        self.event = event
        self.data = data
    }

    public var eventName: String { event }
}

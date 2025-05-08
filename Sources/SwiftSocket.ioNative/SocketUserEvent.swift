//
//  SocketUserEvent.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 08/05/25.
//

import Foundation

public enum SocketUserEvent: Hashable, CustomStringConvertible, Codable, RawRepresentable {
    case message
    case chatStarted
    case typing
    case stopTyping
    case joinedRoom
    case leftRoom
    case custom(String)

    public var name: String {
        switch self {
        case .message: return "message"
        case .chatStarted: return "chatStarted"
        case .typing: return "typing"
        case .stopTyping: return "stopTyping"
        case .joinedRoom: return "joinedRoom"
        case .leftRoom: return "leftRoom"
        case .custom(let name): return name
        }
    }

    public var rawValue: String {
        return self.name
    }

    public init(rawValue: String) {
        switch rawValue {
        case "message": self = .message
        case "chatStarted": self = .chatStarted
        case "typing": self = .typing
        case "stopTyping": self = .stopTyping
        case "joinedRoom": self = .joinedRoom
        case "leftRoom": self = .leftRoom
        default: self = .custom(rawValue)
        }
    }

    public var description: String {
        return "📩 Event: \(name)"
    }

    public var isSystemEvent: Bool {
        switch self {
        case .custom: return false
        default: return true
        }
    }
}

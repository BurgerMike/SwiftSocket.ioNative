import Foundation

/// Eventos internos de conexión con contexto opcional
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

/// Estado general del socket
public enum SocketState: String, Codable {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case failed
}

/// Tipo de mensaje intercambiado entre cliente y servidor
public enum SocketMessageType: String, Codable {
    case event
    case ack
    case error
    case ping
    case pong
}

/// Eventos de usuario emitibles o escuchables
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

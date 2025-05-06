
import Foundation

/// Eventos internos de conexión con contexto opcional
public enum SocketConnectionEvent: Equatable, CustomStringConvertible {
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

/// Eventos de usuario emitibles o escuchables
public enum SocketUserEvent: Hashable, CustomStringConvertible {
    case message
    case chatStarted
    case typing
    case stopTyping
    case custom(String)

    public var name: String {
        switch self {
        case .message: return "message"
        case .chatStarted: return "chatStarted"
        case .typing: return "typing"
        case .stopTyping: return "stopTyping"
        case .custom(let name): return name
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

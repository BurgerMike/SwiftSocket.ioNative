import Foundation

public enum EngineIOPacketType: Int, CustomStringConvertible, Codable, SocketIOCodablePacket {
    case open = 0, close, ping, pong, message, upgrade, noop

    public var code: Int { rawValue }

    public init?(rawCode: Int) {
        self.init(rawValue: rawCode)
    }

    public var description: String {
        switch self {
        case .open: return "open"
        case .close: return "close"
        case .ping: return "ping"
        case .pong: return "pong"
        case .message: return "message"
        case .upgrade: return "upgrade"
        case .noop: return "noop"
        }
    }

    public init?(stringValue: String) {
        guard let int = Int(stringValue) else { return nil }
        self.init(rawValue: int)
    }
}

public enum SocketIOMessageType: Int, CustomStringConvertible, Codable, SocketIOCodablePacket {
    case connect = 0, disconnect, event, ack, error, binary

    public var code: Int { rawValue }

    public init?(rawCode: Int) {
        self.init(rawValue: rawCode)
    }

    public var description: String {
        switch self {
        case .connect: return "connect"
        case .disconnect: return "disconnect"
        case .event: return "event"
        case .ack: return "ack"
        case .error: return "error"
        case .binary: return "binary"
        }
    }

    public init?(stringValue: String) {
        guard let int = Int(stringValue) else { return nil }
        self.init(rawValue: int)
    }
}

public enum SocketIOError: Error, CustomStringConvertible {
    case connectionFailed(reason: String)
    case encodingFailed(reason: String)
    case decodingFailed(event: String, reason: String)
    case disconnected
    case unknown(message: String)
    case authenticationFailed(reason: String)

    public var description: String {
        switch self {
        case .connectionFailed(let reason): return "🔌 Connection failed: \(reason)"
        case .encodingFailed(let reason): return "📦 Failed to encode data: \(reason)"
        case .decodingFailed(let event, let reason): return "📥 Error decoding event '\(event)': \(reason)"
        case .disconnected: return "🔕 Disconnected from the server"
        case .unknown(let message): return "❗️Unknown error: \(message)"
        case .authenticationFailed(let reason): return "🔐 Authentication failure: \(reason)"
        }
    }
}

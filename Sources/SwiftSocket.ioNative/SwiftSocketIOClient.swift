import Foundation

public final class SwiftSocketIOClient: SocketClient {
    private var webSocket: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    private let url: URL
    private let path: String
    private let namespace: String
    private let auth: [String: String]
    private let ackManager = AckManager()
    private var listeners: [String: [(Any) -> Void]] = [:]
    private var systemListeners: [String: [(Any) -> Void]] = [:]
    private var isConnected = false
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private let reconnectInterval: TimeInterval = 3

    public init(url: URL, path: String = "/socket.io", namespace: String = "/", auth: [String: String] = [:]) {
        self.url = url
        self.path = path
        self.namespace = namespace
        self.auth = auth
    }

    public func connect() {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.path = path + namespace
        components.queryItems = [
            URLQueryItem(name: "EIO", value: "4"),
            URLQueryItem(name: "transport", value: "websocket")
        ]

        guard let finalURL = components.url else {
            notifySystem(event: "connect_error", data: SocketError.connectionFailed(reason: "Invalid URL"))
            return
        }

        var request = URLRequest(url: finalURL)
        request.addValue("websocket", forHTTPHeaderField: "Upgrade")

        webSocket = session.webSocketTask(with: request)
        webSocket?.resume()

        if !auth.isEmpty {
            let authPayload = try? JSONSerialization.data(withJSONObject: ["auth": auth], options: [])
            if let jsonString = authPayload.flatMap({ String(data: $0, encoding: .utf8) }) {
                sendRaw("40\(jsonString)")
            } else {
                sendRaw("40")
            }
        } else {
            sendRaw("40")
        }

        receive()
    }

    public func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        isConnected = false
        notifySystem(event: "disconnect", data: "User disconnected")
    }

    public func emit(event: String, data: Encodable?, ack: ((Any?) -> Void)?) {
        var payload: [Any] = [event]
        if let data = data {
            if let encoded = try? JSONEncoder().encode(data),
               let json = try? JSONSerialization.jsonObject(with: encoded) {
                payload.append(json)
            }
        }

        if let ack = ack {
            let ackId = UUID().uuidString
            ackManager.storeAck(id: ackId, callback: ack)
            sendRaw("42\(ackId)\(serialize(payload))")
        } else {
            sendRaw("42\(serialize(payload))")
        }
    }

    public func on(event: String, callback: @escaping (Any) -> Void) {
        listeners[event, default: []].append(callback)
    }

    public func onSystem(event: String, callback: @escaping (Any) -> Void) {
        systemListeners[event, default: []].append(callback)
    }

    public func off(event: String) {
        listeners.removeValue(forKey: event)
    }

    private func receive() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                default:
                    break
                }
            case .failure(let error):
                self.isConnected = false
                self.notifySystem(event: "connect_error", data: error)
                self.tryReconnect()
            }
            self.receive() // continuar escuchando
        }
    }

    private func handleMessage(_ text: String) {
        if text.hasPrefix("40") {
            isConnected = true
            reconnectAttempts = 0
            notifySystem(event: "connect", data: "Connected")
            return
        }

        if text.hasPrefix("42") {
            let jsonStart = text.index(text.startIndex, offsetBy: 2)
            let payloadText = String(text[jsonStart...])
            if let data = payloadText.data(using: .utf8),
               let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
               let event = array.first as? String {
                let payload = array.count > 1 ? array[1] : nil
                listeners[event]?.forEach { $0(payload as Any) }
            }
        }
    }

    private func tryReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            notifySystem(event: "reconnect_failed", data: "Max attempts reached")
            return
        }

        reconnectAttempts += 1
        DispatchQueue.global().asyncAfter(deadline: .now() + reconnectInterval) {
            self.notifySystem(event: "reconnecting", data: self.reconnectAttempts)
            self.connect()
        }
    }

    private func notifySystem(event: String, data: Any) {
        systemListeners[event]?.forEach { $0(data) }
    }

    private func sendRaw(_ string: String) {
        webSocket?.send(.string(string)) { error in
            if let error = error {
                self.notifySystem(event: "error", data: error)
            }
        }
    }

    private func serialize(_ payload: [Any]) -> String {
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "[]"
    }
}
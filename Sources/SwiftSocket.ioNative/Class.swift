import Foundation


public final class SwiftNativeSocketIOClient: NativeSocketClient {
    
    private var messageQueue: [String] = []
    private var reconnectDelay: TimeInterval = 2.0

    private var webSocket: URLSessionWebSocketTask?
    private let serverURL: URL
    private var session: URLSession
    private(set) public var isConnected: Bool = false
    private var eventHandlers: [String: (Any) -> Void] = [:]
    private var authUserId: String?

    private var pingTimer: Timer?
    private var lastConnectionEvent: SocketConnectionEvent?

    public var pendingUserId: String?

    public var onEvent: ((SocketConnectionEvent) -> Void)?
    public weak var errorDelegate: SocketErrorHandler?
    private let id: Int
    private let baseURL: URL
    private let path: String
    private let queryItems: [URLQueryItem]
    

    public init(id: Int, baseURL: URL, path: String, queryItems: [URLQueryItem], authUserId: String? = nil) {
        self.id = id
        self.baseURL = baseURL
        self.path = path
        self.queryItems = queryItems

        // Construye la URL final
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.path = path
        components.queryItems = queryItems

        guard let fullURL = components.url else {
            fatalError("URL inválida al construir WebSocket")
        }

        self.serverURL = fullURL
        self.session = URLSession(configuration: .default)
        self.authUserId = authUserId
        self.pendingUserId = authUserId
    }
    public func connect(with userId: String?) {
        var request = URLRequest(url: serverURL)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        if let userId = userId {
            let authPayload = ["userId": userId]
            if let jsonData = try? JSONSerialization.data(withJSONObject: authPayload),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                request.addValue(jsonString, forHTTPHeaderField: "auth")
            }
        }

        webSocket = session.webSocketTask(with: request)
        webSocket?.resume()
        startPing()
        isConnected = true
        if lastConnectionEvent != .connected {
            lastConnectionEvent = .connected
            onEvent?(.connected)
        }
        flushQueue()
        listen()
    }

    public func disconnect() {
        stopPing()
        if lastConnectionEvent != .disconnected {
            lastConnectionEvent = .disconnected
            onEvent?(.disconnected)
        }
        webSocket?.cancel(with: .normalClosure, reason: nil)
        isConnected = false
    }

    public func emit(event: SocketUserEvent, data: CodableValue) {
        do {
            let message = try SocketMessage(event: event.name, data: data).encodedString()
            if isConnected {
                webSocket?.send(.string(message)) { error in
                    if let error = error {
                        self.errorDelegate?.socketDidCatchError(.encodingFailed(reason: error.localizedDescription))
                    }
                }
            } else {
                messageQueue.append(message)
            }
        } catch {
            self.errorDelegate?.socketDidCatchError(.encodingFailed(reason: error.localizedDescription))
        }
    }

    public func on(event: SocketUserEvent, callback: @escaping (CodableValue) -> Void) {
        eventHandlers[event.name] = { raw in
            if let value = raw as? CodableValue {
                callback(value)
            }
        }
    }

    public func off(event: String) {
        eventHandlers.removeValue(forKey: event)
    }

    private func listen() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.isConnected = false
                    let newEvent = SocketConnectionEvent.connectionError(error.localizedDescription)
                    if case .connectionError(let lastReason) = self.lastConnectionEvent,
                       lastReason == error.localizedDescription {
                        // same error, don't re-emit
                    } else {
                        self.lastConnectionEvent = newEvent
                        self.onEvent?(newEvent)
                    }
                    // Reconnect logic removed

                case .success(let message):
                    switch message {
                    case .string(let text):
                        self.handleTextMessage(text)
                    default:
                        break
                    }
                }

                // Siempre volvemos a escuchar
                self.listen()
            }
        }
    }

    private func handleTextMessage(_ text: String) {
        do {
            let message = try SocketMessage.decode(from: text)
            if let handler = eventHandlers[message.event] {
                handler(message.data)
            } else {
                print("⚠️ No handler for event:", message.event)
            }
        } catch {
            self.errorDelegate?.socketDidCatchError(.decodingFailed(event: "unknown", reason: error.localizedDescription))
        }
    }

    private func startPing() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 25, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }

    private func stopPing() {
        pingTimer?.invalidate()
        pingTimer = nil
    }

    private func sendPing() {
        webSocket?.sendPing { error in
            if let error = error {
                print("❌ Error al enviar ping:", error)
                self.disconnect()
            } else {
                print("✅ Ping enviado")
            }
        }
    }

    private func flushQueue() {
        for msg in messageQueue {
            webSocket?.send(.string(msg)) { _ in }
        }
        messageQueue.removeAll()
    }
}

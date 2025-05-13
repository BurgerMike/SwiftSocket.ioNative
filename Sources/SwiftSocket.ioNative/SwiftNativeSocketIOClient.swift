import Foundation

public final class SwiftNativeSocketIOClient: SocketClient {
    private var url: URL
    private var task: URLSessionWebSocketTask?
    private let session: URLSession
    private var eventHandlers: [String: (Any) -> Void] = [:]
    private var reconnectManager = ReconnectManager()
    private let ackManager = AckManager()

    private var authUserId: String?
    private var socketPath: String

    public init(baseURL: URL, path: String = "/socket.io", userId: String?) {
        self.url = baseURL
        self.socketPath = path
        self.authUserId = userId
        self.session = URLSession(configuration: .default)
    }

    public func connect() {
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.path = socketPath
        urlComponents.queryItems = [
            URLQueryItem(name: "EIO", value: "4"),
            URLQueryItem(name: "transport", value: "websocket")
        ]
        if let userId = authUserId {
            urlComponents.queryItems?.append(URLQueryItem(name: "userId", value: userId))
        }

        guard let finalURL = urlComponents.url else { return }

        task = session.webSocketTask(with: finalURL)
        task?.resume()

        listen()
    }

    public func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
    }

    // ✅ Corrección: emit usando tipo genérico T: Encodable
    public func emit<T: Encodable>(event: String, data: T?, ack: ((Any?) -> Void)? = nil) {
        let socketEvent = SocketEvent(event: event, data: data)
        guard let encoded = try? JSONEncoder().encode(socketEvent),
              let jsonString = String(data: encoded, encoding: .utf8) else {
            return
        }

        if let ack = ack {
            let ackId = UUID().uuidString
            ackManager.addAck(id: ackId, callback: ack)
            send("\(jsonString)#\(ackId)")
        } else {
            send(jsonString)
        }
    }

    public func on(event: String, callback: @escaping (Any) -> Void) {
        eventHandlers[event] = callback
    }

    public func off(event: String) {
        eventHandlers.removeValue(forKey: event)
    }

    private func listen() {
        task?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                print("❌ WebSocket error:", error)
                self.reconnectManager.start { self.connect() }

            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                default:
                    break
                }

                self.listen()
            }
        }
    }

    private func send(_ text: String) {
        task?.send(.string(text)) { error in
            if let error = error {
                print("❌ Error al enviar mensaje:", error)
            }
        }
    }

    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let event = try? JSONDecoder().decode(SocketEvent.self, from: data) else {
            return
        }

        if let handler = eventHandlers[event.event] {
            if let payload = event.data {
                handler(payload)
            } else {
                handler(())
            }
        }
    }
}

// ✅ Extensión para recibir eventos con tipos decodificados automáticamente
public extension SwiftNativeSocketIOClient {
    func on<T: Decodable>(
        event: String,
        decodeTo type: T.Type,
        callback: @escaping (T) -> Void
    ) {
        on(event: event) { any in
            guard let socketEvent = any as? SocketEvent else { return }
            if let decoded = socketEvent.decodedData(as: T.self) {
                callback(decoded)
            }
        }
    }
}

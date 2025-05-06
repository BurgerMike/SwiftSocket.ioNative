import Foundation


private struct AuthPayload: Codable {
    let userId: String
}


public final class SwiftNativeSocketIOClient: NativeSocketClient {
    private var webSocket: URLSessionWebSocketTask?
    private let serverURL: URL
    private var session: URLSession
    private(set) public var isConnected: Bool = false
    private var eventHandlers: [String: (Any) -> Void] = [:]
    private var authUserId: String?

    public var pendingUserId: String?

    public var onConnect: (() -> Void)?
    public var onDisconnect: ((Error?) -> Void)?
    public weak var errorDelegate: SocketErrorHandler?
    private let baseURL: URL
    private let path: String
    private let queryItems: [URLQueryItem]
    

    public init(baseURL: URL, path: String, queryItems: [URLQueryItem]) {
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
    }

    public func connect() {
        var request = URLRequest(url: serverURL)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        webSocket = session.webSocketTask(with: request)
        webSocket?.resume()
        isConnected = true
        onConnect?()
        listen()

        if let userId = pendingUserId {
            sendInitialAuth(userId: userId)
            pendingUserId = nil
        }
    }

    public func disconnect() {
        onDisconnect?(nil)
        webSocket?.cancel(with: .normalClosure, reason: nil)
        isConnected = false
    }

    public func authenticate(with userId: String) {
        authUserId = userId
        pendingUserId = userId
        if isConnected {
            sendInitialAuth(userId: userId)
        }
    }

    private func sendInitialAuth(userId: String) {
        let payload = SocketEmitPayload(event: "auth", data: AuthPayload(userId: userId))
        emit(payload)
    }

    public func emit<T: Encodable>(event: String, data: T)
    {      let payload = SocketEmitPayload(event: event, data: data)
        emit(payload)
    }

    public func emit<T: SocketEmittable>(_ payload: T) {
        do {
            let encoded = try JSONEncoder().encode(payload)
            if let jsonString = String(data: encoded, encoding: .utf8) {
                let wrapped = "[\"\(payload.eventName)\", \(jsonString)]"
                let socketMessage = "42" + wrapped
                webSocket?.send(.string(socketMessage)) { error in
                    if let error = error {
                        self.errorDelegate?.socketDidCatchError(.encodingFailed(reason: error.localizedDescription))
                    }
                }
            }
        } catch {
            self.errorDelegate?.socketDidCatchError(.encodingFailed(reason: error.localizedDescription))
        }
    }

    public func on<T: Decodable>(event: String, callback: @escaping (T) -> Void) {
        eventHandlers[event] = { raw in
            do {
                let data = try JSONSerialization.data(withJSONObject: raw)
                let decoded = try JSONDecoder().decode(T.self, from: data)
                callback(decoded)
            } catch {
                self.errorDelegate?.socketDidCatchError(.decodingFailed(event: event, reason: error.localizedDescription))
            }
        }
    }

    public func off(event: String) {
        eventHandlers.removeValue(forKey: event)
    }

    private func listen() {
        webSocket?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                self.isConnected = false
                self.errorDelegate?.socketDidCatchError(.connectionFailed(reason: error.localizedDescription))
                self.onDisconnect?(error)

            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleTextMessage(text)
                default:
                    break
                }
                self.listen()
            }
        }
    }

    private func handleTextMessage(_ text: String) {
        guard text.hasPrefix("42"),
              let jsonStart = text.firstIndex(of: "[") else {
            self.errorDelegate?.socketDidCatchError(.unknown(message: "Received message without expected prefix or format"))
            return
        }

        let payload = String(text[jsonStart...])
        guard let data = payload.data(using: .utf8),
              let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
              array.count == 2,
              let event = array[0] as? String else {
            self.errorDelegate?.socketDidCatchError(.unknown(message: "Failed to parse incoming socket message"))
            return
        }

        let body = array[1]

        eventHandlers[event]?(body)
    }
}

//
//  Class.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 14/05/25.
//
import Foundation


/// Administra los callbacks `ack` de eventos emitidos que esperan respuesta del servidor.
final class AckManager {
    private var acks: [String: (Any?) -> Void] = [:]
    private let queue = DispatchQueue(label: "AckManagerQueue", attributes: .concurrent)
    
    /// Registra un callback para un ID específico.
    func storeAck(id: String, callback: @escaping (Any?) -> Void) {
        queue.async(flags: .barrier) {
            self.acks[id] = callback
        }
    }
    
    /// Resuelve un ack cuando el servidor responde con un evento que incluye ese ID.
    func resolveAck(id: String, with response: Any?) {
        queue.async(flags: .barrier) {
            if let callback = self.acks.removeValue(forKey: id) {
                DispatchQueue.main.async {
                    callback(response)
                }
            }
        }
    }
    
    /// Limpia todos los acks pendientes (por desconexión, error, etc.)
    func reset() {
        queue.async(flags: .barrier) {
            self.acks.removeAll()
        }
    }
}

// Sources/SwiftSocketIONative/EventRouter.swift

final class EventRouter {
    private var listeners: [String: [(CodableValue?) -> Void]] = [:]
    
    init() {}
    
    /// Registra un callback para un evento específico.
    func on(_ event: String, callback: @escaping (CodableValue?) -> Void) {
        listeners[event, default: []].append(callback)
    }
    
    /// Elimina todos los callbacks para un evento específico.
    func off(_ event: String) {
        listeners.removeValue(forKey: event)
    }
    
    /// Ejecuta todos los callbacks registrados para el evento recibido.
    func handle(event: SocketEvent) {
        guard let callbacks = listeners[event.event] else { return }
        
        for callback in callbacks {
            callback(event.payload)
        }
    }
    
    /// Limpia todos los eventos registrados (opcional, por reconexión, logout, etc.).
    func clearAll() {
        listeners.removeAll()
    }
}

public final class SwiftSocketIOClient: SocketClient {
    private var webSocketTask: URLSessionWebSocketTask?
    private let url: URL
    private let session: URLSession
    private let eventRouter = EventRouter()
    private let ackManager = AckManager()
    private let auth: [String: String]?
    private let path: String
    
    private var usePing: Bool = false
    private var pingInterval: TimeInterval = 10
    private var pingTimer: Timer?
    
    private var printedMessageIds = Set<String>()
    private let maxLoggedMessages = 100
    
    public var debugMode: Bool = false
    
    public init(
        url: URL,
        path: String = "",
        auth: [String: String]? = nil,
        usePing: Bool = false,
        pingInterval: TimeInterval = 10
    ) {
        self.url = url
        self.path = path
        self.auth = auth
        self.usePing = usePing
        self.pingInterval = pingInterval
        
        let config = URLSessionConfiguration.default
        if let auth = auth {
            config.httpAdditionalHeaders = auth
        }
        self.session = URLSession(configuration: config)
    }
    
    public func connect() {
        var urlComponents = URLComponents(url: url.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if let auth = auth {
            urlComponents?.queryItems = auth.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let fullURL = urlComponents?.url else { return }
        
        webSocketTask = session.webSocketTask(with: fullURL)
        webSocketTask?.resume()
        
        receiveMessages()
        if usePing { startPingLoop() }
        eventRouter.handle(event: SocketEvent(event: "connect", payload: nil))
        
    }
    
    public func disconnect() {
        stopPingLoop()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        eventRouter.handle(event: SocketEvent(event: "disconnect", payload: nil))
        
    }
    
    public func emit(event: String, data: Encodable?, ack: ((Any?) -> Void)? = nil) {
        var socketEvent = SocketEvent(event: event)
        
        if let data = data, let payload = CodableValue.encode(from: data) {
            socketEvent = SocketEvent(event: event, payload: payload)
        }
        
        if let ack = ack {
            let id = UUID().uuidString
            ackManager.storeAck(id: id, callback: ack)
            socketEvent = SocketEvent(
                event: event,
                payload: socketEvent.payload,
                id: id,
                timestamp: Date(),
                senderId: auth?["userId"]
            )
        }
        
        do {
            let messageData = try JSONEncoder().encode(socketEvent)
            webSocketTask?.send(.data(messageData)) { error in
                if let error = error {
                    if self.debugMode {
                        print("❌ Error al enviar mensaje:", error)
                    }
                }
            }
        } catch {
            if debugMode {
                print("❌ No se pudo codificar SocketEvent")
            }
        }
    }
    
    public func on(event: String, callback: @escaping (Any) -> Void) {
        eventRouter.on(event) { payload in
            callback(payload as Any)
        }
    }
    
    public func off(event: String) {
        eventRouter.off(event)
    }
    
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            defer { self.receiveMessages() }
            
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    if let event = try? JSONDecoder().decode(SocketEvent.self, from: data) {
                        if let id = event.id {
                            ackManager.resolveAck(id: id, with: event.payload)
                        }
                        
                        if let msgId = event.id, !printedMessageIds.contains(msgId) {
                            printedMessageIds.insert(msgId)
                            if printedMessageIds.count > maxLoggedMessages {
                                printedMessageIds.removeFirst()
                            }
                            
                            self.eventRouter.handle(event: event)
                        }
                    }
                default: break
                }
            case .failure(let error):
                if self.debugMode {
                    print("❌ Error al recibir mensaje:", error)
                }
            }
        }
    }
    
    private func startPingLoop() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: pingInterval, repeats: true) { [weak self] _ in
            self?.emit(event: "ping", data: nil)
        }
    }
    
    private func stopPingLoop() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
}

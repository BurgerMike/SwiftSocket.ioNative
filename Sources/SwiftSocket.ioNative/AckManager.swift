//
//  AckManager.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 13/05/25.
//

import Foundation

final class AckManager {
    private var ackHandlers: [String: (Any?) -> Void] = [:]
    private let queue = DispatchQueue(label: "AckManagerQueue")

    func addAck(id: String, callback: @escaping (Any?) -> Void) {
        queue.sync {
            ackHandlers[id] = callback
        }
    }

    func callAck(id: String, with data: Any?) {
        queue.sync {
            if let callback = ackHandlers.removeValue(forKey: id) {
                callback(data)
            }
        }
    }
}

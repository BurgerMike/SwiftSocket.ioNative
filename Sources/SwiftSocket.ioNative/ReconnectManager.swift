//
//  RecconectManager.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 13/05/25.
//

import Foundation

final class ReconnectManager {
    var maxRetries = 5
    private var currentRetry = 0
    private var timer: Timer?

    func start(_ attempt: @escaping () -> Void) {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.currentRetry < self.maxRetries {
                self.currentRetry += 1
                attempt()
            } else {
                self.stop()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        currentRetry = 0
    }
}

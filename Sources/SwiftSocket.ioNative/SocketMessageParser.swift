//
//  SocketMessageParser.swift
//  SwiftSocket.ioNative
//
//  Created by Miguel Carlos Elizondo Martinez on 07/05/25.
//
import Foundation

struct SocketMessageParser {
    static func parse(_ raw: String) -> SocketParsedMessage? {
        // Ejemplo: "42[\"chat\",{\"msg\":\"hola\"}]"
        guard let code = raw.first?.wholeNumberValue else { return nil }

        if code == 42, let jsonStart = raw.firstIndex(of: "[") {
            let jsonString = String(raw[jsonStart...])
            guard let data = jsonString.data(using: .utf8),
                  let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
                  let event = array.first as? String else { return nil }

            let content = array.dropFirst().first
            let wrapped = try? JSONSerialization.data(withJSONObject: content ?? [:])
            let decoded = try? JSONDecoder().decode(CodableValue.self, from: wrapped ?? Data())

            return SocketParsedMessage(code: code, event: event, data: decoded)
        }

        return SocketParsedMessage(code: code, event: nil, data: nil)
    }
}

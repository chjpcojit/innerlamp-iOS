//
//  SecurityAlertReporter.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

/// Nhóm 2 — Security Alerts.
/// Payload gửi thẳng tới Risk server nội bộ, không qua Sentry hay bất kỳ third-party nào.
public final class SecurityAlertReporter: SecurityAlertReporting {
    public static let shared = SecurityAlertReporter(transport: MockLogTransport.shared)

    private let transport: LogTransport

    public init(transport: LogTransport) {
        self.transport = transport
    }

    public func send(event: SecurityEvent, metadata: [String: String] = [:]) {
        let payload = SecurityAlertPayload(
            event: event.rawValue,
            sessionId: CorrelationContext.shared.currentSessionId,
            timestamp: Date().timeIntervalSince1970,
            metadata: metadata
        )
        // Gọi thẳng, không qua buffer, không qua queue.
        transport.send(destination: .riskServer, payload: payload)
    }
}

private struct SecurityAlertPayload: Encodable {
    let event: String
    let sessionId: String
    let timestamp: TimeInterval
    let metadata: [String: String]
}

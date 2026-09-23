//
//  SecurityAlertReporting.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

/// Nhóm 2 — Security Alerts.
/// Gửi thẳng, real-time, không qua buffer/queue — jailbreak có thể xóa file log trước khi
/// batch kịp chạy, nên phải push ngay khi phát hiện.
public protocol SecurityAlertReporting: AnyObject {
    func send(event: SecurityEvent, metadata: [String: String])
}

public extension SecurityAlertReporting {
    func send(event: SecurityEvent) {
        send(event: event, metadata: [:])
    }
}

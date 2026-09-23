//
//  LogTransport.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

/// Server đích — mỗi nhóm log có infrastructure riêng, không dùng chung.
public enum LogDestination: String {
    case riskServer      = "risk_server"       // Nhóm 2 — Security Alerts
    case metricsServer   = "metrics_server"    // Nhóm 3 — Metrics
    case analyticsServer = "analytics_server"  // Nhóm 4 — Flow Tracking
}

/// Interface đẩy payload lên server nội bộ. Tách khỏi `LoggingService` (Sentry) vì
/// đích đến và ràng buộc PII hoàn toàn khác nhau — xem "Overview" trong spec.
public protocol LogTransport {
    func send<T: Encodable>(destination: LogDestination, payload: T)
}

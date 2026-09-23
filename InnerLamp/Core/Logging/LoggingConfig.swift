//
//  LoggingConfig.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation

/// Cấu hình tập trung cho toàn bộ hệ thống logging (4 nhóm).
/// TODO: Thay giá trị mock bằng config thật (DSN production, URL server nội bộ) trước khi release.
///
/// `nonisolated` — chỉ là hằng số thuần, không giữ state. Cần thiết vì `SentryLoggingService`
/// (nonisolated) đọc `sentryDSN`/`environment` từ `start()`. Target bật
/// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` nên phải opt out tường minh.
nonisolated public enum LoggingConfig {
    /// DSN Sentry cho Nhóm 1 — Crash Reports.
    public static let sentryDSN = "https://mock-dsn@o0.ingest.sentry.io/0"

    #if DEBUG
    public static let environment = "development"
    #else
    public static let environment = "production"
    #endif

    /// Server nội bộ cho Nhóm 2 — Security Alerts. Mock, chưa có backend thật.
    public static let riskServerBaseURL = "https://mock-risk.internal.innerlamp.app"

    /// Server nội bộ cho Nhóm 3 — Metrics. Mock, chưa có backend thật.
    public static let metricsServerBaseURL = "https://mock-metrics.internal.innerlamp.app"

    /// Server nội bộ cho Nhóm 4 — Flow Tracking. Mock, chưa có backend thật.
    public static let analyticsServerBaseURL = "https://mock-analytics.internal.innerlamp.app"
}

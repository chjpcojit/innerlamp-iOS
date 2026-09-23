//
//  SentryLoggingService.swift
//  InnerLamp
//
//  Created by Antigravity on 12/9/26.
//

import Foundation
import Sentry

/// Nhóm 1 — Crash Reports.
/// Business code không được phụ thuộc trực tiếp SentrySDK — mọi tương tác đi qua
/// `LoggingService` protocol. Đây là implementation cụ thể duy nhất biết đến Sentry.
///
/// PII masking được enforce tại đây, không phó mặc cho caller — mọi message/metadata
/// đi qua `PIIMasker` trước khi rời khỏi app, vì Sentry là third-party service ngoài
/// perimeter của app.
/// `nonisolated` — mọi method ở đây chỉ chuyển tiếp sang `SentrySDK` (thread-safe) và không
/// giữ state nào. Cần thiết vì `NetworkServiceImpl` (một actor) đọc `shared` từ nonisolated
/// default argument của `init`; xem `NetworkService.swift:31`.
nonisolated public final class SentryLoggingService: LoggingService {
    public static let shared = SentryLoggingService()

    private init() {}

    /// Gọi một lần duy nhất khi app khởi động.
    public func start(dsn: String = LoggingConfig.sentryDSN, environment: String = LoggingConfig.environment) {
        SentrySDK.start { options in
            options.dsn = dsn
            options.environment = environment
            options.maxBreadcrumbs = 50
            options.enableAutoBreadcrumbTracking = true

            // Bắt buộc tắt — màn hình tại thời điểm crash có thể đang hiển thị dữ liệu nhạy cảm.
            options.attachScreenshot = false
            options.attachViewHierarchy = false
        }
    }

    public func breadcrumb(category: BreadcrumbCategory, message: String, data: [String: Any]?) {
        let crumb = Breadcrumb()
        crumb.category = category.rawValue
        crumb.message = PIIMasker.maskMessage(message)
        crumb.data = data.map(PIIMasker.maskMetadata)
        crumb.level = .info
        SentrySDK.addBreadcrumb(crumb)
    }

    public func log(level: LogLevel, message: String, metadata: [String: Any]?) {
        let maskedMessage = PIIMasker.maskMessage(message)
        let maskedMetadata = metadata.map(PIIMasker.maskMetadata)

        SentrySDK.capture(message: maskedMessage) { scope in
            scope.setLevel(level.sentryLevel)
            if let maskedMetadata {
                scope.setContext(value: maskedMetadata, key: "metadata")
            }
        }
    }

    public func setUserContext(_ context: UserContext) {
        let user = User()
        user.userId = context.sessionId // UUID random mỗi session — không phải user ID thật
        user.data = [
            "device_tier": context.deviceTier,
            "app_version": context.appVersion
        ]
        SentrySDK.setUser(user)
    }

    public func clearUserContext() {
        SentrySDK.setUser(nil)
    }
}

private extension LogLevel {
    var sentryLevel: SentryLevel {
        switch self {
        case .debug:   return .debug
        case .info:    return .info
        case .warning: return .warning
        case .error:   return .error
        case .fatal:   return .fatal
        }
    }
}

//
//  ILRateLimitMessage.swift
//  InnerLamp
//

import Foundation

/// EN: Builds the "try again later" message for `429 RATE_LIMITED` on any `/v1/auth/*` route, with the
///     wait from `details.retry_after_seconds`. Shared by the Login, SignUp and Otp feature errors.
///     Foundation only.
/// VI: Dựng câu "thử lại sau" cho `429 RATE_LIMITED` của mọi route `/v1/auth/*`, với thời gian chờ
///     lấy từ `details.retry_after_seconds`. Dùng chung cho lỗi của Login, SignUp và Otp. Chỉ dùng Foundation.
enum ILRateLimitMessage {

    /// EN: Falls back to a message without a number when the server sent no usable wait.
    /// VI: Trả câu không kèm số khi server không gửi thời gian chờ dùng được.
    static func text(retryAfterSeconds: Int?) -> String {
        guard let retryAfterSeconds, retryAfterSeconds > 0 else {
            return "auth.error.rateLimited".localized
        }
        return String(format: "auth.error.rateLimitedSeconds".localized, retryAfterSeconds)
    }
}

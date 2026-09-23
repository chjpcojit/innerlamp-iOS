//
//  LocalizationConfig.swift
//  InnerLamp
//

import Foundation

/// Cấu hình tập trung cho hệ thống đa ngôn ngữ.
/// TODO: Thay `serverBaseURL` bằng URL production thật trước khi release (xem
/// `LoggingConfig` — cùng convention, mock vì backend chưa sẵn sàng).
enum LocalizationConfig {
    static let serverBaseURL = "https://mock-i18n.internal.innerlamp.app"

    /// Ngôn ngữ mặc định — app chưa có màn đổi ngôn ngữ nên luôn dùng giá trị này.
    static let defaultLanguage = "vi"
}

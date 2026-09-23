//
//  String+Localized.swift
//  InnerLamp
//

import Foundation

extension String {
    /// Tra bản dịch hiện tại theo key qua `LocalizationServiceImpl.shared`. Dùng cho
    /// text tĩnh trong UI: `label.text = "onboarding.title".localized`. Key không có
    /// trong file ngôn ngữ sẽ trả lại chính key đó, không crash.
    var localized: String {
        LocalizationServiceImpl.shared.string(for: self)
    }
}

//
//  LocalizationModels.swift
//  InnerLamp
//

import Foundation

/// 1 bộ string dịch cho 1 ngôn ngữ. Luôn có `version` để so với server —
/// server chỉ trả bản mới khi version đổi, tránh tải lại file không đổi.
nonisolated struct LocalizedStringsFile: Codable, Equatable {
    let version: String
    let language: String
    let strings: [String: String]
}

//
//  ILSutraDetailEntity.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation

/// Một phẩm (mục lục) của bản dịch — `sections[]` của `GET /v1/sutras/{id}`.
nonisolated struct ILSutraDetailChapterEntity: Equatable, Identifiable {
    let id: String
    /// Số thứ tự hiển thị ("1", "2", ...) theo thứ tự server.
    let number: String
    let title: String
    let lineCount: Int
}

/// Một bản kinh / kệ / chú đầy đủ để hiển thị ở màn chi tiết — `GET /v1/sutras/{id}`.
nonisolated struct ILSutraDetailSutraEntity: Equatable, Identifiable {
    let id: String
    let title: String
    /// Tên nguyên ngữ (Pāli / Anh) khi khác `title`; rỗng nếu không có.
    let originalTitle: String
    let kind: ILSutraKind?
    let tradition: ILSutraTradition?
    let collection: String
    let reference: String
    let isDailyChant: Bool
    let purposes: [ILSutraPurpose]
    let durationMinutes: Int?
    /// Bản dịch ưu tiên (tiếng Việt nếu có) — nguồn của các trường dưới đây và của `chapters`.
    let translator: String
    let sourceName: String
    /// Chỉ giữ link `http(s)` tuyệt đối.
    let sourceURL: String?
    let license: String
    let lineCount: Int
    let chapters: [ILSutraDetailChapterEntity]
}

/// Pure business entity cho màn Chi tiết bài kinh — Domain layer only.
struct ILSutraDetailEntity: Equatable {
    var sutra: ILSutraDetailSutraEntity?

    static let empty = ILSutraDetailEntity()
}

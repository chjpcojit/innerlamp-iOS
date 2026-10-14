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

/// Vai của một vị Phật / Bồ tát trong bài kinh.
nonisolated enum ILSutraDeityRole: Equatable {
    case speaker
    case subject
    case mentioned
}

/// Loại bản dịch của một văn bản — `translations[].variant`.
nonisolated enum ILSutraTranslationVariant: Equatable {
    case translation
    case chant
    case meaning
    case poem
}

/// Một vị Phật / Bồ tát liên quan tới bài kinh — `deities[]` của `GET /v1/sutras/{id}`.
nonisolated struct ILSutraDetailDeityEntity: Equatable, Identifiable {
    let id: String
    let name: String
    /// `nil` khi server trả vai mà app chưa biết.
    let role: ILSutraDeityRole?
}

/// Tên của bài kinh bằng một ngôn ngữ khác (`titles` ngoài tên hiển thị và tên nguyên ngữ).
nonisolated struct ILSutraDetailAlternateTitleEntity: Equatable {
    /// Mã ngôn ngữ của server: `en`, `pli`, `sa`, `zh`, ...
    let language: String
    let text: String
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
    // Detail-only fields (BE contract 2026-10-11); `""` / `nil` / `[]` when the server has no value.
    /// Giới thiệu do AI soạn — rỗng cho tới khi backend seed.
    var summary: String = ""
    var author: String = ""
    var hanTranslator: String = ""
    var hanTranslationYear: Int?
    var referenceNote: String = ""
    var deities: [ILSutraDetailDeityEntity] = []
    var alternateTitles: [ILSutraDetailAlternateTitleEntity] = []
    /// `true` khi server gắn trạng thái duyệt (hiện chỉ có `UNREVIEWED`) — giá trị lạ cũng coi là chưa duyệt.
    var isUnreviewed: Bool = false
    var variant: ILSutraTranslationVariant?
    /// Chỉ giữ link `http(s)` tuyệt đối.
    var licenseURL: String?
    var licenseNote: String = ""
    var note: String = ""
}

/// Pure business entity cho màn Chi tiết bài kinh — Domain layer only.
struct ILSutraDetailEntity: Equatable {
    var sutra: ILSutraDetailSutraEntity?

    static let empty = ILSutraDetailEntity()
}

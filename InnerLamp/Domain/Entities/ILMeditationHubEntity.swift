//
//  ILMeditationHubEntity.swift
//  InnerLamp
//

import Foundation

/// 1 preset "Thiền chuông" (tự hành trì) trong màn Thiền định — chỉ dữ liệu nghiệp vụ, không có
/// trạng thái UI. Copy đã resolve `.localized` ở tầng UseCase (xem `references/design_tokens_rules.md`).
struct ILMeditationHubPresetEntity: Equatable {
    let id: String
    let name: String
    /// Thời gian ngồi của preset (phút).
    let minutes: Int
    let subtitle: String
}

/// 1 bài "Thiền dẫn" (thiền có hướng dẫn) trong màn Thiền định.
struct ILMeditationHubGuidedEntity: Equatable {
    let id: String
    /// Dòng phương pháp in hoa (vd. "QUÁN NIỆM HƠI THỞ · ANAPANASATI").
    let method: String
    let name: String
    let teacher: String
    let minutes: Int
    let summary: String
    /// Đã tải về máy hay chưa — trạng thái nghiệp vụ (sau này đọc/ghi qua Repository).
    var isDownloaded: Bool
}

/// Pure business entity cho màn "Thiền định" (design handoff `medhub`) — Domain layer only.
///
/// Chỉ chứa dữ liệu nghiệp vụ (chuỗi ngày, số phút theo ngày, danh mục preset thiền chuông và bài
/// thiền dẫn). Không có trường UI-only (`*Error`, `isSubmitting`, tab đang chọn, chuỗi đã format)
/// — những thứ đó nằm ở `ILMeditationHubStateModel`
/// (`Presentation/Scenes/MeditationHub/`). Xem `references/data_layer_boundaries.md`.
struct ILMeditationHubEntity: Equatable {
    /// Số ngày thiền liên tục.
    var streakDays: Int = 0
    /// Tổng số phút thiền trong tuần này.
    var weeklyMinutes: Int = 0
    /// Số phút thiền của 84 ngày gần nhất, xếp **theo hàng** để khớp lưới heatmap 12 cột × 7 hàng:
    /// `index = dayIndex * 12 + weekIndex` (dayIndex 0...6 trong tuần, weekIndex 0...11 tuần).
    var dailyMinutes: [Int] = []
    var presets: [ILMeditationHubPresetEntity] = []
    var guidedSessions: [ILMeditationHubGuidedEntity] = []

    static let empty = ILMeditationHubEntity()
}

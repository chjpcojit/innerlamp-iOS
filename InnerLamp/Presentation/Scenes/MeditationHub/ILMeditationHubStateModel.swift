//
//  ILMeditationHubStateModel.swift
//  InnerLamp
//

import Foundation

/// Tab đang chọn ở màn Thiền định — UI state thuần, không phải dữ liệu nghiệp vụ.
enum ILMeditationHubTabKind: Equatable {
    /// "Thiền chuông" — danh sách preset tự hành trì.
    case timer
    /// "Thiền dẫn" — danh sách bài thiền có hướng dẫn.
    case guided
}

/// 1 tab trong segmented control dưới header.
struct ILMeditationHubTabModel: Equatable {
    let kind: ILMeditationHubTabKind
    let title: String
    let isSelected: Bool
}

/// Thẻ "N ngày thiền liên tục" + heatmap 12 tuần — đã format sẵn.
struct ILMeditationHubSummaryModel: Equatable {
    let valueText: String
    let unitText: String
    let noteText: String
    /// Alpha (0...1) từng ô heatmap, điền theo hàng (12 cột × 7 hàng).
    let intensities: [CGFloat]
    let startLabel: String
    let endLabel: String
    let accessibilityLabel: String
}

/// 1 hàng preset "Thiền chuông" — đã format sẵn.
struct ILMeditationHubPresetModel: Equatable, Identifiable {
    let id: String
    let minutesText: String
    let minutesUnitText: String
    let name: String
    let subtitle: String
    let accessibilityLabel: String
}

/// 1 thẻ bài "Thiền dẫn" — đã format sẵn.
struct ILMeditationHubGuidedModel: Equatable, Identifiable {
    let id: String
    let method: String
    let name: String
    let metaText: String
    let summary: String
    let downloadTitle: String
    let isDownloaded: Bool
    let accessibilityLabel: String
}

/// Trạng thái UI của màn Thiền định — Presentation layer, do `ILMeditationHubViewModel` sở hữu và
/// cập nhật độc quyền. Không UIKit, không business logic — ViewController chỉ đọc để hiển thị. Chứa
/// các chuỗi `.localized` đã resolve và giá trị đã format, khác với dữ liệu thô nằm trên
/// `ILMeditationHubEntity` (xem `references/data_layer_boundaries.md`).
struct ILMeditationHubStateModel: Equatable {
    var headerTitle: String = ""
    var headerSubtitle: String = ""

    var tabs: [ILMeditationHubTabModel] = []
    var selectedTab: ILMeditationHubTabKind = .timer

    var summary: ILMeditationHubSummaryModel?

    var timerSectionTitle: String = ""
    var presets: [ILMeditationHubPresetModel] = []
    var customTimerTitle: String = ""

    var guidedSectionTitle: String = ""
    var guidedSessions: [ILMeditationHubGuidedModel] = []

    var showsTimerSection: Bool { selectedTab == .timer }
    var showsGuidedSection: Bool { selectedTab == .guided }

    static let initial = ILMeditationHubStateModel()
}

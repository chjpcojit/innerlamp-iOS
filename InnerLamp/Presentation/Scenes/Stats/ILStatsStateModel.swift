//
//  ILStatsStateModel.swift
//  InnerLamp
//

import Foundation

/// "Chuỗi ngày tinh tấn" featured card, ready to display.
struct ILStatsStreakModel: Equatable {
    let valueText: String
    let unitText: String
    /// nil hides the milestone note and progress bar (every milestone already earned).
    let milestoneText: String?
    /// 0...1 — streak progress towards the next milestone.
    let milestoneProgress: Double
}

/// Tone of a stat tile's footnote.
enum ILStatsFootnoteTone: Equatable {
    /// Improvement (e.g. "+8 giờ so với tháng trước") — rendered green.
    case positive
    case neutral
}

/// One half-width stat tile ("Tổng thời gian", "Giờ ngồi quen").
struct ILStatsTileModel: Equatable {
    let title: String
    let valueText: String
    /// Empty when the value carries no unit (e.g. a clock time).
    let unitText: String
    let footnote: String
    let footnoteTone: ILStatsFootnoteTone
}

/// One bar of the weekly duration chart.
struct ILStatsBarModel: Equatable {
    /// 0...1 relative to the tallest week.
    let heightRatio: Double
    /// 0...1 bar opacity — busier weeks read darker.
    let opacity: Double
}

/// "Thời lượng 12 tuần" chart card.
struct ILStatsWeeklyChartModel: Equatable {
    let title: String
    let averageText: String
    let bars: [ILStatsBarModel]
    let startLabel: String
    let endLabel: String
}

/// One practice kind in the "Phân bổ pháp hành" breakdown.
struct ILStatsMixItemModel: Equatable {
    let kind: ILStatsPracticeKind
    let name: String
    /// 0...1 share of the segmented bar.
    let fraction: Double
    let percentText: String
}

/// UI state of the Stats screen — owned by `ILStatsViewModel`, the ViewController only reads it to render.
struct ILStatsStateModel: Equatable {
    var streak = ILStatsStreakModel(valueText: "", unitText: "", milestoneText: nil, milestoneProgress: 0)
    var tiles: [ILStatsTileModel] = []
    var weeklyChart: ILStatsWeeklyChartModel?
    var mix: [ILStatsMixItemModel] = []
    var reminderSubtitle: String = ""

    var hasMix: Bool { !mix.isEmpty }

    static let initial = ILStatsStateModel()
}

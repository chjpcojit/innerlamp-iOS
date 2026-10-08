//
//  ILReaderStateModel.swift
//  InnerLamp
//

import Foundation

/// One row of the chant list: either a section heading or a chanted line.
enum ILReaderRowState: Equatable {
    case heading(String)
    case line(ILReaderLineRowState)
}

/// A chanted line as rendered: text, optional English gloss, cue glyph ("◉" / "•" / ""), and
/// whether it is the highlighted (currently chanted) line.
struct ILReaderLineRowState: Equatable {
    let text: String
    let gloss: String
    let cueGlyph: String
    let isCurrent: Bool
}

/// Pace chip ("1x" / "1.2x" / "1.5x").
struct ILReaderSpeedOptionState: Equatable {
    let speed: Double
    let title: String
    let isSelected: Bool
}

/// UI state of the Reader ("Tụng kinh") screen — Presentation layer, owned and updated exclusively
/// by `ILReaderViewModel`. No UIKit, no business logic: the view controller only renders it.
/// `themeIndex` / `fontSizeIndex` are plain indexes; the view maps them to colors and fonts.
struct ILReaderStateModel: Equatable {
    // Header
    var title: String = ""
    /// "Đang tụng · <narrator>" / "Tạm dừng · chạm để tụng tiếp" / "Chỉ có văn bản".
    var statusText: String = ""
    var fontSizeActionTitle: String = ""

    // Auto-scroll toggle row
    var autoScrollTitle: String = ""
    var keepAwakeNote: String = ""
    /// "Chạm để tạm dừng" / "Chạm để tiếp tục".
    var hintText: String = ""
    var isAutoScrollEnabled: Bool = true

    // Settings panel
    var isSettingsVisible: Bool = false
    var fontSizeTitle: String = ""
    var fontSizeOptionTitle: String = ""
    var backgroundTitle: String = ""
    var themeTitles: [String] = []
    var fontSizeIndex: Int = 1
    var themeIndex: Int = 0

    // Chant list
    var rows: [ILReaderRowState] = []
    /// Index into `rows` of the highlighted line (headings count as rows); `nil` when no lines.
    var currentRowIndex: Int?
    var legendBellText: String = ""
    var legendKnockText: String = ""

    // Bottom controls
    var hasAudio: Bool = false
    var positionText: String = ""
    var durationText: String = ""
    var progress: Double = 0
    var isPlaying: Bool = false
    var seekBackTitle: String = ""
    var seekForwardTitle: String = ""
    var speedLabel: String = ""
    var speedOptions: [ILReaderSpeedOptionState] = []

    static let initial = ILReaderStateModel()
}

//
//  ILBellStateModel.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation

/// UI state for the "Chuông mõ" screen — Presentation layer, owned and mutated exclusively by
/// `ILBellViewModel`. No UIKit import, no business logic — the `ViewController` only reads this to
/// render. It carries every display concern the screen needs (resolved `.localized` labels,
/// formatted values, the raw counts the view uses to detect a new strike) while the raw business
/// values live on `ILBellEntity` — see `references/data_layer_boundaries.md`.
struct ILBellStateModel: Equatable {
    // Header
    var headerTitle: String = ""
    var headerSubtitle: String = ""

    // Preset chips
    var presetLabels: [String] = []
    var selectedPresetIndex: Int = 0

    // Mode segmented control
    var modeLabels: [String] = []
    var selectedMode: ILBellMode = .moAndBell

    // "Thỉnh chuông sau mỗi" row (only visible in mo + bell mode)
    var everyOptionLabels: [String] = []
    var selectedEveryIndex: Int = 0
    var showEveryRow: Bool = false

    // Rhythm / interval card
    var rateLabel: String = ""
    var rateValue: String = ""

    // Center pad
    var padTag: String = ""
    var padNumber: Int = 0
    var padHint: String = ""

    // Playback flags (mirrored from the entity for rendering)
    var isRunning: Bool = false
    var isRolling: Bool = false

    // Strike counters — raw for the view to compare, plus pre-formatted labels.
    var moCount: Int = 0
    var bellCount: Int = 0
    var moCountText: String = ""
    var bellCountText: String = ""

    // Bottom action bar
    var leftButtonTitle: String = ""
    var ringBellTitle: String = ""

    static let initial = ILBellStateModel()
}

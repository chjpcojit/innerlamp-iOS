//
//  ILBellEntity.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation

/// Playback mode of the "Chuông mõ" (bell & wooden-fish) screen. Raw values match the design's
/// `bMode` (0/1/2) and the segment order in the UI.
enum ILBellMode: Int, Equatable, CaseIterable {
    /// Wooden fish only.
    case mo = 0
    /// Bell only.
    case bell = 1
    /// Wooden fish + bell — a bell is struck automatically after every N wooden-fish strikes.
    case moAndBell = 2
}

/// A practice preset (Tụng kinh / Niệm Phật / ...). `titleKey` is a localization key resolved by
/// the Presentation layer — the Domain keeps only the stable identifier, never a display string.
struct ILBellPreset: Equatable {
    let titleKey: String
    let mode: ILBellMode
    /// Beats per minute for the wooden fish (`nil` when the preset is bell-only).
    let bpm: Int?
    /// Seconds between auto bell strikes (`nil` when the preset is not bell-only).
    let gapSeconds: Int?
    /// Strike a bell after every N wooden-fish strikes (`nil` when not applicable).
    let everyCount: Int?
}

/// Pure business entity for the "Chuông mõ" screen — Domain layer only.
///
/// Holds only values with real business meaning for a bell/mo practice session: the session
/// configuration (`mode`, `bpm`, `gapSeconds`, `everyCount`, `presetIndex`), the strike counters,
/// and the playback flags (`isRunning`, `isRolling`) that describe whether the session's rhythmic
/// striking is currently active. The flags are session *state*, not display formatting — they are
/// reset every time the screen is opened (like `moCount`/`bellCount`), so nothing here is persisted
/// yet. UI-only concerns (formatted strings, labels, the transient strike flash) live in
/// `ILBellStateModel` instead — see `references/data_layer_boundaries.md`.
struct ILBellEntity: Equatable {
    var mode: ILBellMode = .moAndBell
    /// Beats per minute, clamped to 40...160 (drives the wooden-fish / auto rhythm).
    var bpm: Int = 72
    /// Seconds between auto bell strikes, clamped to 5...120 (bell-only mode).
    var gapSeconds: Int = 15
    /// Auto-bell milestone: 0 = off, or one of 10 / 27 / 108.
    var everyCount: Int = 27
    /// Index into `ILBellUseCase.presets`, or -1 when the user has customized the settings.
    var presetIndex: Int = 0
    /// Total wooden-fish strikes this session.
    var moCount: Int = 0
    /// Total bell strikes this session.
    var bellCount: Int = 0
    /// Whether the auto rhythm is currently running (steady striking).
    var isRunning: Bool = false
    /// Whether the "dồn mõ" (accelerating roll) sequence is currently playing.
    var isRolling: Bool = false

    static let empty = ILBellEntity()
}

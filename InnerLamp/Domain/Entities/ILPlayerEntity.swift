//
//  ILPlayerEntity.swift
//  InnerLamp
//

import Foundation

/// A single audio track shown in the full-screen player — matches `player` in the design handoff
/// (`Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`).
struct ILPlayerTrackEntity: Equatable, Identifiable {
    let id: String
    /// Chapter / track headline, e.g. "Phẩm Song Yếu".
    let title: String
    /// Secondary line under the title, e.g. "Kinh Pháp Cú · Thầy Minh Đạo".
    let subtitle: String
    /// Total audio duration (seconds) — used to compute progress and remaining time.
    let totalDurationSeconds: Int
}

/// Pure business entity for the full-screen player — Domain layer only.
///
/// Holds the track catalog, the currently-playing track, playback position and the two user
/// controls (playback-speed index, sleep-timer index) plus the in-memory play/pause flag. All
/// formatted strings ("14:22", "-23:18", "0.75×", the sleep note) are UI state and live on
/// `ILPlayerStateModel` instead — see `references/data_layer_boundaries.md`.
struct ILPlayerEntity: Equatable {
    var tracks: [ILPlayerTrackEntity] = []
    var currentTrackID: String = ""
    /// Playback position (seconds).
    var elapsedSeconds: Int = 0
    /// Index into the speed options ("0.75×", "1.0×", "1.25×", "1.5×").
    var playbackSpeedIndex: Int = 1
    /// Index into the sleep-timer options ("Tắt", "15p", "30p", "Hết bài").
    var sleepTimerIndex: Int = 1
    /// Playing / paused — in-memory flag until real audio lands.
    var isPlaying: Bool = false

    static let empty = ILPlayerEntity()
}

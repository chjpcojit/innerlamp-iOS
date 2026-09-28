//
//  ILPlayerStateModel.swift
//  InnerLamp
//

import Foundation

/// UI state for the full-screen player — Presentation layer, owned and mutated exclusively by
/// `ILPlayerViewModel`. No UIKit, no business logic — the ViewController only reads this to render.
/// Holds the resolved `.localized` labels and pre-formatted values ("14:22", "-23:18", "1.0×") and
/// the two option lists with their selected indices; the raw data lives on `ILPlayerEntity` (see
/// `references/data_layer_boundaries.md`).
struct ILPlayerStateModel: Equatable {
    var headerTitle: String = ""
    var tableOfContentsActionTitle: String = ""

    var trackTitle: String = ""
    var trackSubtitle: String = ""

    /// Position labels under the progress bar.
    var elapsedText: String = ""
    var remainingText: String = ""
    /// Playback progress (0...1).
    var playbackProgress: Double = 0
    /// Playing / paused (drives the play/pause button glyph).
    var isPlaying: Bool = false

    /// Seek control labels.
    var rewindTitle: String = ""
    var forwardTitle: String = ""

    var speedSectionTitle: String = ""
    var speedOptions: [String] = []
    var selectedSpeedIndex: Int = 1

    var sleepSectionTitle: String = ""
    var sleepOptions: [String] = []
    var selectedSleepIndex: Int = 1

    /// Footnote under the sleep-timer options (depends on the selected option).
    var sleepNote: String = ""

    static let initial = ILPlayerStateModel()
}

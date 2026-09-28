//
//  ILMeditationSessionStateModel.swift
//  InnerLamp
//

import Foundation

/// UI state of the "Phiên thiền" screen — Presentation layer, owned and mutated exclusively by
/// `ILMeditationSessionViewModel` (via `applyEntity(_:)`). Holds resolved `.localized` copy and
/// display formatting ("mm:ss"), as opposed to the raw progress on `ILMeditationSessionEntity`.
struct ILMeditationSessionStateModel: Equatable {
    var headerTitle: String = ""
    /// "20 phút" (guided) or "20 phút · im lặng" (silent).
    var headerSubtitle: String = ""

    /// Countdown, "mm:ss".
    var timerText: String = ""
    /// "còn lại · 20 phút"
    var timerCaption: String = ""

    /// Breath cue (Vietnamese) + its English line. Both empty for a silent sit — no guidance.
    var cueText: String = ""
    var cueTranslation: String = ""

    /// Drives the breathing-ring animation: which way the rings move and how long until the
    /// phase flips.
    var breathPhase: ILBreathPhase = .inhale
    var secondsLeftInBreathPhase: Int = 0

    /// `true` while the session is counting down (shows the pause glyph).
    var isPlaying: Bool = true

    var endEarlyTitle: String = ""

    var exitAccessibilityLabel: String = ""
    var pauseAccessibilityLabel: String = ""
    var resumeAccessibilityLabel: String = ""
    var endAccessibilityLabel: String = ""

    static let initial = ILMeditationSessionStateModel()
}

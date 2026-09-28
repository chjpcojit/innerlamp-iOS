//
//  ILMeditationSessionEntity.swift
//  InnerLamp
//

import Foundation

/// Direction of the breath the session is currently guiding.
enum ILBreathPhase: Equatable {
    case inhale
    case exhale
}

/// Pure business entity for the "Phiên thiền" screen (design handoff `session`) — Domain layer only.
///
/// Holds the session's configuration (duration, guided or silent) and its progress (elapsed time,
/// running or paused), plus the breath rhythm derived from that progress. It must NOT contain
/// UI-only fields (localized labels, formatted "mm:ss", accessibility copy) — those live in
/// `ILMeditationSessionStateModel` (`Presentation/Scenes/MeditationSession/`).
struct ILMeditationSessionEntity: Equatable {
    /// Breath rhythm from the design handoff: 4s in, 6s out (one 10s cycle).
    static let inhaleSeconds = 4
    static let exhaleSeconds = 6
    static var breathCycleSeconds: Int { inhaleSeconds + exhaleSeconds }

    /// Total length of the sit, in seconds.
    var durationSeconds: Int

    /// Seconds already sat — only advances while `isRunning`.
    var elapsedSeconds: Int = 0

    /// `true` for a guided session ("Bắt đầu"), `false` for a silent sit ("Ngồi im lặng").
    var isGuided: Bool

    /// `false` while paused or once the session has ended.
    var isRunning: Bool = true

    var remainingSeconds: Int {
        max(durationSeconds - elapsedSeconds, 0)
    }

    var isCompleted: Bool {
        elapsedSeconds >= durationSeconds
    }

    var breathPhase: ILBreathPhase {
        positionInBreathCycle < Self.inhaleSeconds ? .inhale : .exhale
    }

    /// Seconds until the current breath phase flips (inhale ↔ exhale).
    var secondsLeftInBreathPhase: Int {
        let position = positionInBreathCycle
        return position < Self.inhaleSeconds
            ? Self.inhaleSeconds - position
            : Self.breathCycleSeconds - position
    }

    private var positionInBreathCycle: Int {
        elapsedSeconds % Self.breathCycleSeconds
    }
}

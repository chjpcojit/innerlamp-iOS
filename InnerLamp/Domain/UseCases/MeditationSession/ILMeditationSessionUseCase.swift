//
//  ILMeditationSessionUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILMeditationSessionUseCase {
    /// Builds a fresh, running session. Durations below one minute are clamped to one minute.
    func makeSession(durationMinutes: Int, isGuided: Bool) -> ILMeditationSessionEntity

    /// Advances a running session by one second. Paused or already-completed sessions are returned
    /// unchanged; the tick that reaches the full duration also stops the session.
    func tick(_ session: ILMeditationSessionEntity) -> ILMeditationSessionEntity

    /// Pauses a running session or resumes a paused one. A completed session stays stopped.
    func togglePause(_ session: ILMeditationSessionEntity) -> ILMeditationSessionEntity

    /// Stops the session (natural end or "Kết thúc sớm") without changing the elapsed time.
    func endSession(_ session: ILMeditationSessionEntity) -> ILMeditationSessionEntity

    /// Persists the finished sit into the practice log (streak, weekly minutes, practice mix).
    func recordSession(_ session: ILMeditationSessionEntity) async throws
}

final class ILMeditationSessionUseCaseImpl: ILMeditationSessionUseCase {

    // No external dependency yet: every rule below is a pure in-memory computation. A practice-log
    // Repository gets injected here together with the real `recordSession` implementation.
    init() {}

    func makeSession(durationMinutes: Int, isGuided: Bool) -> ILMeditationSessionEntity {
        ILMeditationSessionEntity(durationSeconds: max(durationMinutes, 1) * 60, isGuided: isGuided)
    }

    func tick(_ session: ILMeditationSessionEntity) -> ILMeditationSessionEntity {
        guard session.isRunning, !session.isCompleted else { return session }
        var next = session
        next.elapsedSeconds += 1
        if next.isCompleted {
            next.isRunning = false
        }
        return next
    }

    func togglePause(_ session: ILMeditationSessionEntity) -> ILMeditationSessionEntity {
        guard !session.isCompleted else { return session }
        var next = session
        next.isRunning.toggle()
        return next
    }

    func endSession(_ session: ILMeditationSessionEntity) -> ILMeditationSessionEntity {
        var next = session
        next.isRunning = false
        return next
    }

    func recordSession(_ session: ILMeditationSessionEntity) async throws {
        print("TODO: implement recordSession — practice-log repository call, not built by ui-builder")
    }
}

//
//  ILBellUseCase.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import Foundation

protocol ILBellUseCase {
    /// The five practice presets (Tụng kinh / Niệm Phật / Lạy sám hối / Ngồi thiền / Chỉ gõ mõ).
    var presets: [ILBellPreset] { get }
    /// Auto-bell milestones: `[0 (off), 10, 27, 108]`.
    var everyOptions: [Int] { get }

    func getInitialState() -> ILBellEntity

    /// Apply a preset (by index) — override the fields the preset defines and stop any playback.
    func selectPreset(_ index: Int, on entity: ILBellEntity) -> ILBellEntity
    /// Switch playback mode — mark the session as customized (preset = -1) and stop playback.
    func selectMode(_ mode: ILBellMode, on entity: ILBellEntity) -> ILBellEntity
    /// Choose the auto-bell milestone (value from `everyOptions`) — mark as customized.
    func selectEvery(_ value: Int, on entity: ILBellEntity) -> ILBellEntity
    /// Nudge the rhythm: bell-only mode adjusts `gapSeconds` by ±5 (clamped 5...120), other modes
    /// adjust `bpm` by ±4 (clamped 40...160). Marks the session as customized.
    func adjustRate(by delta: Int, on entity: ILBellEntity) -> ILBellEntity

    /// Strike one wooden fish.
    func strikeMo(_ entity: ILBellEntity) -> ILBellEntity
    /// Strike one bell.
    func strikeBell(_ entity: ILBellEntity) -> ILBellEntity
    /// Whether a bell should automatically follow the last wooden-fish strike (mo + bell mode and
    /// the current count has just reached the `everyCount` milestone).
    func shouldRingBellAfterMo(_ entity: ILBellEntity) -> Bool

    /// Reset counters and stop all playback (roll / steady rhythm).
    func resetCounters(_ entity: ILBellEntity) -> ILBellEntity
    /// Start / stop the steady auto rhythm.
    func setRunning(_ running: Bool, on entity: ILBellEntity) -> ILBellEntity
    /// Start / stop the "dồn mõ" roll.
    func setRolling(_ rolling: Bool, on entity: ILBellEntity) -> ILBellEntity

    /// Seconds between two auto strikes under the current configuration.
    func intervalSeconds(for entity: ILBellEntity) -> TimeInterval
}

final class ILBellUseCaseImpl: ILBellUseCase {

    // Audio is deliberately not handled here: the Domain layer is framework-free, and playing sound
    // is a Presentation-layer concern. `ILBellViewModel` routes every strike through the injected
    // `ILPracticeSoundPlaying` (see `Core/Audio`), so this UseCase stays pure and unit-testable.
    init() {}

    static let presets: [ILBellPreset] = [
        ILBellPreset(titleKey: "bell.preset.chanting", mode: .moAndBell, bpm: 72, gapSeconds: nil, everyCount: 27),
        ILBellPreset(titleKey: "bell.preset.reciting", mode: .moAndBell, bpm: 96, gapSeconds: nil, everyCount: 108),
        ILBellPreset(titleKey: "bell.preset.prostration", mode: .bell, bpm: nil, gapSeconds: 12, everyCount: nil),
        ILBellPreset(titleKey: "bell.preset.meditation", mode: .bell, bpm: nil, gapSeconds: 60, everyCount: nil),
        ILBellPreset(titleKey: "bell.preset.moOnly", mode: .mo, bpm: 60, gapSeconds: nil, everyCount: nil),
    ]

    static let everyOptions: [Int] = [0, 10, 27, 108]

    var presets: [ILBellPreset] { Self.presets }
    var everyOptions: [Int] { Self.everyOptions }

    func getInitialState() -> ILBellEntity {
        // The default entity already matches preset 0 ("Tụng kinh": mode .moAndBell, bpm 72,
        // everyCount 27, gapSeconds 15) — see `ILBellEntity.empty`.
        ILBellEntity()
    }

    func selectPreset(_ index: Int, on entity: ILBellEntity) -> ILBellEntity {
        guard Self.presets.indices.contains(index) else { return entity }
        let preset = Self.presets[index]
        var result = entity
        result.mode = preset.mode
        if let bpm = preset.bpm { result.bpm = bpm }
        if let gapSeconds = preset.gapSeconds { result.gapSeconds = gapSeconds }
        if let everyCount = preset.everyCount { result.everyCount = everyCount }
        result.presetIndex = index
        result.isRunning = false
        result.isRolling = false
        return result
    }

    func selectMode(_ mode: ILBellMode, on entity: ILBellEntity) -> ILBellEntity {
        var result = entity
        result.mode = mode
        result.presetIndex = -1
        result.isRunning = false
        result.isRolling = false
        return result
    }

    func selectEvery(_ value: Int, on entity: ILBellEntity) -> ILBellEntity {
        var result = entity
        result.everyCount = value
        result.presetIndex = -1
        return result
    }

    func adjustRate(by delta: Int, on entity: ILBellEntity) -> ILBellEntity {
        var result = entity
        if result.mode == .bell {
            result.gapSeconds = min(120, max(5, result.gapSeconds + delta * 5))
        } else {
            result.bpm = min(160, max(40, result.bpm + delta * 4))
        }
        result.presetIndex = -1
        return result
    }

    func strikeMo(_ entity: ILBellEntity) -> ILBellEntity {
        var result = entity
        result.moCount += 1
        return result
    }

    func strikeBell(_ entity: ILBellEntity) -> ILBellEntity {
        var result = entity
        result.bellCount += 1
        return result
    }

    func shouldRingBellAfterMo(_ entity: ILBellEntity) -> Bool {
        entity.mode == .moAndBell
            && entity.everyCount > 0
            && entity.moCount > 0
            && entity.moCount % entity.everyCount == 0
    }

    func resetCounters(_ entity: ILBellEntity) -> ILBellEntity {
        var result = entity
        result.moCount = 0
        result.bellCount = 0
        result.isRunning = false
        result.isRolling = false
        return result
    }

    func setRunning(_ running: Bool, on entity: ILBellEntity) -> ILBellEntity {
        var result = entity
        result.isRunning = running
        return result
    }

    func setRolling(_ rolling: Bool, on entity: ILBellEntity) -> ILBellEntity {
        var result = entity
        result.isRolling = rolling
        return result
    }

    func intervalSeconds(for entity: ILBellEntity) -> TimeInterval {
        entity.mode == .bell ? TimeInterval(entity.gapSeconds) : 60.0 / Double(entity.bpm)
    }
}

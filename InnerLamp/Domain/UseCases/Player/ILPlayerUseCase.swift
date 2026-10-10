//
//  ILPlayerUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILPlayerUseCase {
    /// Catalog of playable tracks with the track matching `sutraID` selected as the current one.
    func getInitialState(sutraID: String) -> ILPlayerEntity

    /// The track currently playing (`nil` if the id is not in the catalog).
    func currentTrack(in entity: ILPlayerEntity) -> ILPlayerTrackEntity?

    /// Toggle play/pause — pure in-memory flag (no real audio yet, see TODO note below).
    func togglePlayPause(_ entity: ILPlayerEntity) -> ILPlayerEntity

    /// Seek back 15 seconds (clamped to 0).
    func rewind(_ entity: ILPlayerEntity) -> ILPlayerEntity

    /// Seek forward 30 seconds (clamped to the track's total duration).
    func forward(_ entity: ILPlayerEntity) -> ILPlayerEntity

    /// Select a playback speed by index (clamped to the valid option range).
    func selectSpeed(_ entity: ILPlayerEntity, index: Int) -> ILPlayerEntity

    /// Select a sleep-timer option by index (clamped to the valid option range).
    func selectSleepTimer(_ entity: ILPlayerEntity, index: Int) -> ILPlayerEntity
}

final class ILPlayerUseCaseImpl: ILPlayerUseCase {

    /// Seconds to skip back when tapping the "15s" control.
    static let rewindSeconds = 15
    /// Seconds to skip forward when tapping the "30s" control.
    static let forwardSeconds = 30
    /// Number of playback-speed options ("0.75×", "1.0×", "1.25×", "1.5×").
    static let speedOptionCount = 4
    /// Number of sleep-timer options ("Tắt", "15p", "30p", "Hết bài").
    static let sleepOptionCount = 4

    // TODO: when a real sutra-audio contract exists (see "Data cần API" in the design-handoff
    // README), replace the mock catalog below with `ILPlayerRepository` → `networkService`.
    // Likewise `togglePlayPause`/`rewind`/`forward` currently only mutate in-memory state; once
    // there is real audio they must drive the actual player (AVAudioPlayer / a shared audio
    // service). This stays out of ui-builder scope — see `references/data_layer_boundaries.md`.
    init() {}

    func getInitialState(sutraID: String) -> ILPlayerEntity {
        var entity = ILPlayerEntity(
            tracks: Self.makeTrackCatalog(),
            currentTrackID: sutraID,
            elapsedSeconds: 862, // 14:22 — matches the design handoff sample state
            playbackSpeedIndex: 1,
            sleepTimerIndex: 1,
            isPlaying: false
        )
        // Fall back to the first track when the id is not in the mock catalog (same fallback the
        // Reader/Article mock catalogs use for incomplete data).
        if !entity.tracks.contains(where: { $0.id == sutraID }), let first = entity.tracks.first {
            entity.currentTrackID = first.id
        }
        return entity
    }

    func currentTrack(in entity: ILPlayerEntity) -> ILPlayerTrackEntity? {
        entity.tracks.first { $0.id == entity.currentTrackID }
    }

    func togglePlayPause(_ entity: ILPlayerEntity) -> ILPlayerEntity {
        var updated = entity
        updated.isPlaying.toggle()
        return updated
    }

    func rewind(_ entity: ILPlayerEntity) -> ILPlayerEntity {
        var updated = entity
        updated.elapsedSeconds = max(0, entity.elapsedSeconds - Self.rewindSeconds)
        return updated
    }

    func forward(_ entity: ILPlayerEntity) -> ILPlayerEntity {
        var updated = entity
        let total = currentTrack(in: entity)?.totalDurationSeconds ?? entity.elapsedSeconds
        updated.elapsedSeconds = min(total, entity.elapsedSeconds + Self.forwardSeconds)
        return updated
    }

    func selectSpeed(_ entity: ILPlayerEntity, index: Int) -> ILPlayerEntity {
        var updated = entity
        updated.playbackSpeedIndex = min(max(0, index), Self.speedOptionCount - 1)
        return updated
    }

    func selectSleepTimer(_ entity: ILPlayerEntity, index: Int) -> ILPlayerEntity {
        var updated = entity
        updated.sleepTimerIndex = min(max(0, index), Self.sleepOptionCount - 1)
        return updated
    }

    // MARK: - Catalog

    /// Mock catalog with a single track (Kinh Pháp Cú) matching `player` in the design handoff.
    /// Copy resolved through `.localized`, the same way `ILReaderUseCaseImpl`/`ILArticleUseCaseImpl`
    /// build their mock catalogs. Other library sutras (Vu Lan, A Di Đà, Chú Đại Bi) have no audio
    /// data yet, so they are intentionally left out.
    private static func makeTrackCatalog() -> [ILPlayerTrackEntity] {
        [
            ILPlayerTrackEntity(
                id: "sutra.phapcu",
                title: "player.track.phapcu.chapter".localized,
                subtitle: "player.track.phapcu.subtitle".localized,
                totalDurationSeconds: 2260 // 37:40 → matches "14:22" / "-23:18" sample
            )
        ]
    }
}

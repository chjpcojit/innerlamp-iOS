//
//  ILReaderUseCase.swift
//  InnerLamp
//

import Foundation

protocol ILReaderUseCase {
    /// Catalog with `sutraID` selected; chanting starts at line 0 and, for sutras with audio,
    /// already playing (the "Tụng theo" entry in the design handoff).
    func getInitialState(sutraID: String) -> ILReaderEntity

    /// Sutra matching `currentSutraID` (`nil` if the id is not in the catalog).
    func currentSutra(in entity: ILReaderEntity) -> ILReaderSutraEntity?

    /// Flip play/pause. Pure in-memory (see TODO below).
    func togglePlayPause(_ entity: ILReaderEntity) -> ILReaderEntity

    /// Move the highlight by `delta` lines, clamped to the sutra's lines (design: −10s / +10s
    /// buttons jump 2 lines).
    func seek(_ entity: ILReaderEntity, byLines delta: Int) -> ILReaderEntity

    /// Select the chanting pace multiplier.
    func setSpeed(_ entity: ILReaderEntity, to speed: Double) -> ILReaderEntity

    /// Account for `milliseconds` of wall-clock time while playing: advances to the next line each
    /// time the scaled accumulator reaches the line duration, and pauses on the last line.
    func advance(_ entity: ILReaderEntity, byMilliseconds milliseconds: Double) -> ILReaderEntity

    /// Position within the chant (0...1) derived from the highlighted line.
    func progress(in entity: ILReaderEntity) -> Double

    /// Elapsed chant time in seconds derived from `progress(in:)` and the sutra duration.
    func elapsedSeconds(in entity: ILReaderEntity) -> Int
}

final class ILReaderUseCaseImpl: ILReaderUseCase {

    /// Wall-clock time (at 1.0×) spent on each line — the prototype advances every 2.6s.
    static let lineAdvanceMilliseconds: Double = 2600

    // TODO: replace the static catalog with `ILReaderRepository` → `networkService` once the sutra
    // text API exists, and wire `isPlaying` to a real recitation audio player. Until then the
    // highlight advances on a timer and no sound is played (see Docs/Tech-Debt/Reader/).
    init() {}

    func getInitialState(sutraID: String) -> ILReaderEntity {
        let sutras = Self.makeSutraCatalog()
        // Unknown id falls back to the first catalog sutra — the same mock-catalog fallback as
        // Library/SutraDetail.
        let resolved = sutras.first { $0.id == sutraID } ?? sutras.first
        return ILReaderEntity(
            sutras: sutras,
            currentSutraID: resolved?.id ?? sutraID,
            currentLineIndex: 0,
            playbackSpeed: 1.0,
            isPlaying: resolved?.hasAudio ?? false,
            accumulatedMilliseconds: 0
        )
    }

    func currentSutra(in entity: ILReaderEntity) -> ILReaderSutraEntity? {
        entity.sutras.first { $0.id == entity.currentSutraID }
    }

    func togglePlayPause(_ entity: ILReaderEntity) -> ILReaderEntity {
        var updated = entity
        updated.isPlaying.toggle()
        return updated
    }

    func seek(_ entity: ILReaderEntity, byLines delta: Int) -> ILReaderEntity {
        guard let sutra = currentSutra(in: entity), sutra.lineCount > 0 else { return entity }
        var updated = entity
        updated.currentLineIndex = min(sutra.lineCount - 1, max(0, entity.currentLineIndex + delta))
        updated.accumulatedMilliseconds = 0
        return updated
    }

    func setSpeed(_ entity: ILReaderEntity, to speed: Double) -> ILReaderEntity {
        var updated = entity
        updated.playbackSpeed = speed
        return updated
    }

    func advance(_ entity: ILReaderEntity, byMilliseconds milliseconds: Double) -> ILReaderEntity {
        guard entity.isPlaying, let sutra = currentSutra(in: entity) else { return entity }
        var updated = entity
        updated.accumulatedMilliseconds += milliseconds * entity.playbackSpeed
        guard updated.accumulatedMilliseconds >= Self.lineAdvanceMilliseconds else { return updated }

        updated.accumulatedMilliseconds = 0
        if entity.currentLineIndex >= sutra.lineCount - 1 {
            updated.isPlaying = false
        } else {
            updated.currentLineIndex += 1
        }
        return updated
    }

    func progress(in entity: ILReaderEntity) -> Double {
        guard let sutra = currentSutra(in: entity), sutra.lineCount > 1 else { return 0 }
        return min(1, max(0, Double(entity.currentLineIndex) / Double(sutra.lineCount - 1)))
    }

    func elapsedSeconds(in entity: ILReaderEntity) -> Int {
        guard let sutra = currentSutra(in: entity) else { return 0 }
        return Int((Double(sutra.totalDurationSeconds) * progress(in: entity)).rounded())
    }

    // MARK: - Catalog

    /// Mock catalog of the 11 sutras of the design handoff (`SUTRA_CAT`, same ids as
    /// `ILSutraDetailUseCaseImpl`). Titles/narrators reuse the SutraDetail/Sutras mock keys; the
    /// chanted text exists only for Kinh Pháp Cú and Bát Nhã Tâm Kinh — every other sutra shows the
    /// opening ritual plus a "text coming soon" placeholder, exactly like the prototype.
    private static func makeSutraCatalog() -> [ILReaderSutraEntity] {
        func sutra(_ key: String, minutes: Int, audio: Bool) -> ILReaderSutraEntity {
            ILReaderSutraEntity(
                id: "sutra.\(key)",
                title: "sutras.mock.\(key).name".localized,
                narrator: audio ? "sutraDetail.mock.\(key).narrator".localized : "",
                hasAudio: audio,
                totalDurationSeconds: minutes * 60,
                sections: [makeOpeningSection()] + makeBodySections(for: key)
            )
        }
        return [
            sutra("phapcu", minutes: 130, audio: true),
            sutra("vulan", minutes: 38, audio: true),
            sutra("amida", minutes: 22, audio: true),
            sutra("daibi", minutes: 8, audio: true),
            sutra("tamkinh", minutes: 4, audio: true),
            sutra("phomon", minutes: 25, audio: true),
            sutra("duocsu", minutes: 45, audio: false),
            sutra("diatang", minutes: 120, audio: false),
            sutra("tutam", minutes: 6, audio: true),
            sutra("hanhphuc", minutes: 5, audio: true),
            sutra("chuyenphap", minutes: 15, audio: false)
        ]
    }

    /// "KHAI KINH" ritual shared by every sutra (`RD_OPEN`).
    private static func makeOpeningSection() -> ILReaderSectionEntity {
        makeSection(
            headingKey: "reader.open.heading",
            linesPrefix: "reader.open.line",
            cues: [.bell, .knock, .knock, .knock, .bell],
            glossIndexes: [0]
        )
    }

    /// Chanted text per sutra (`RD_TEXT`); sutras without text get one placeholder section.
    private static func makeBodySections(for key: String) -> [ILReaderSectionEntity] {
        switch key {
        case "phapcu":
            let verseCues: [ILReaderCue] = [.knock, .knock, .knock, .knock, .knock, .bell]
            return [
                makeSection(headingKey: "reader.phapcu.s0.heading", linesPrefix: "reader.phapcu.s0.line",
                            cues: verseCues, glossIndexes: [0]),
                makeSection(headingKey: "reader.phapcu.s1.heading", linesPrefix: "reader.phapcu.s1.line",
                            cues: verseCues),
                makeSection(headingKey: "reader.phapcu.s2.heading", linesPrefix: "reader.phapcu.s2.line",
                            cues: [.knock, .knock, .knock, .bell])
            ]
        case "tamkinh":
            return [
                makeSection(headingKey: "reader.tamkinh.heading", linesPrefix: "reader.tamkinh.line",
                            cues: [.knock, .bell, .knock, .knock, .bell])
            ]
        default:
            return [
                makeSection(headingKey: "reader.placeholder.heading", linesPrefix: "reader.placeholder.line",
                            cues: [.none])
            ]
        }
    }

    /// Builds a section whose line `i` text is `"<linesPrefix>.<i>"` and whose gloss (for
    /// `glossIndexes`) is `"<linesPrefix>.<i>.gloss"`, with one cue per line.
    private static func makeSection(
        headingKey: String,
        linesPrefix: String,
        cues: [ILReaderCue],
        glossIndexes: Set<Int> = []
    ) -> ILReaderSectionEntity {
        let lines = cues.enumerated().map { index, cue in
            ILReaderLineEntity(
                text: "\(linesPrefix).\(index)".localized,
                gloss: glossIndexes.contains(index) ? "\(linesPrefix).\(index).gloss".localized : "",
                cue: cue
            )
        }
        return ILReaderSectionEntity(heading: headingKey.localized, lines: lines)
    }
}

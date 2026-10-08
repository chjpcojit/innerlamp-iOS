//
//  ILReaderEntity.swift
//  InnerLamp
//

import Foundation

/// Ritual cue shown in front of a chanted line — matches `mk` in the design handoff
/// (`InnerLamp Prototype.dc.html`, block `isReader`).
enum ILReaderCue: Equatable {
    case none
    /// "•" — strike the wooden fish.
    case knock
    /// "◉" — ring the bell.
    case bell
}

/// One chanted line of a sutra, with an optional English gloss (e.g. "(3 lần)").
struct ILReaderLineEntity: Equatable {
    let text: String
    let gloss: String
    let cue: ILReaderCue
}

/// A titled run of lines (e.g. "KHAI KINH", "KỆ 2"). The heading is not a line: it never becomes
/// the current line and does not count towards progress.
struct ILReaderSectionEntity: Equatable {
    let heading: String
    let lines: [ILReaderLineEntity]
}

/// A sutra that can be chanted on the Reader screen.
struct ILReaderSutraEntity: Equatable, Identifiable {
    let id: String
    let title: String
    /// Name of the reference chanter (audio voice); empty when the sutra has no audio.
    let narrator: String
    let hasAudio: Bool
    /// Total length of the chant in seconds — used to derive the elapsed/total time labels.
    let totalDurationSeconds: Int
    let sections: [ILReaderSectionEntity]

    /// Number of chantable lines across all sections (headings excluded).
    var lineCount: Int { sections.reduce(0) { $0 + $1.lines.count } }
}

/// Pure business entity of the Reader ("Tụng kinh") screen — Domain layer only.
///
/// Holds the catalog and the chanting position/playback state. UI-only state (theme, font size,
/// settings panel, auto-scroll, formatted labels) lives in `ILReaderStateModel`.
struct ILReaderEntity: Equatable {
    var sutras: [ILReaderSutraEntity] = []
    var currentSutraID: String = ""
    /// Index of the highlighted line, counted across sections (headings excluded).
    var currentLineIndex: Int = 0
    /// Chanting pace multiplier (1.0 / 1.2 / 1.5).
    var playbackSpeed: Double = 1.0
    /// In-memory flag until real audio exists: while `true` the highlight advances on a timer.
    var isPlaying: Bool = false
    /// Milliseconds accumulated towards the next line advance (scaled by `playbackSpeed`).
    var accumulatedMilliseconds: Double = 0

    static let empty = ILReaderEntity()
}

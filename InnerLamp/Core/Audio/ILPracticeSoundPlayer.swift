//
//  ILPracticeSoundPlayer.swift
//  InnerLamp
//
//  Created by ChjpCoj on 26/9/26.
//

import AVFoundation

/// `AVAudioPlayer`-backed implementation of `ILPracticeSoundPlaying`.
///
/// Preloads a small pool of players per sound so rapid strikes (the steady auto rhythm, the
/// accelerating "dồn mõ" roll, or fast bead counting) can overlap without the previous sound being
/// cut short. Loading is resilient: a missing or unreadable asset simply yields an empty pool and
/// playback becomes a no-op, so the practice session never fails because of audio.
///
/// Sound assets (all bundled under `Core/Audio/Resources`):
/// - `bell_strike.m4a` — "singing bell hit 2.wav" by ryancacophony (freesound.org, CC0).
/// - `mo_strike.m4a` — "Fischtrommel_Muyu.mp3" by the_very_Real_Horst (freesound.org, CC BY 4.0).
/// - `bead_click.m4a` — "Woodblock-soft.wav" by hollandm (freesound.org, CC0).
final class ILPracticeSoundPlayer: ILPracticeSoundPlaying {

    private static let poolSize = 3

    private let moPlayers: [AVAudioPlayer]
    private let bellPlayers: [AVAudioPlayer]
    private let beadPlayers: [AVAudioPlayer]
    private var moCursor = 0
    private var bellCursor = 0
    private var beadCursor = 0
    private var hasConfiguredAudioSession = false

    // MARK: - Initializer
    init(bundle: Bundle = .main) {
        moPlayers = Self.makePlayers(resource: "mo_strike", bundle: bundle)
        bellPlayers = Self.makePlayers(resource: "bell_strike", bundle: bundle)
        beadPlayers = Self.makePlayers(resource: "bead_click", bundle: bundle)
    }

    // MARK: - ILPracticeSoundPlaying
    func playMo() {
        playNext(in: moPlayers, cursor: &moCursor)
    }

    func playBell() {
        playNext(in: bellPlayers, cursor: &bellCursor)
    }

    func playBead() {
        playNext(in: beadPlayers, cursor: &beadCursor)
    }

    // MARK: - Playback
    private func playNext(in players: [AVAudioPlayer], cursor: inout Int) {
        guard !players.isEmpty else { return }
        configureAudioSessionIfNeeded()
        let player = players[cursor]
        cursor = (cursor + 1) % players.count
        player.currentTime = 0
        player.play()
    }

    private static func makePlayers(resource: String, bundle: Bundle) -> [AVAudioPlayer] {
        guard let url = bundle.url(forResource: resource, withExtension: "m4a") else { return [] }
        return (0..<poolSize).compactMap { _ in
            let player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            return player
        }
    }

    /// `.ambient` mixes with background music and other audio, and respects the device's silent
    /// switch — the correct behavior for short practice sounds in a meditation app.
    ///
    /// Activation is deferred until the first sound actually plays, so the app never grabs (and
    /// holds) the audio session before it's needed. `options: [.mixWithOthers]` makes the mixing
    /// intent explicit (`.ambient` already mixes by default) and guards against future category
    /// changes. The attempt is made only once; a failure is swallowed on purpose so playback can
    /// never break the practice flow.
    private func configureAudioSessionIfNeeded() {
        guard !hasConfiguredAudioSession else { return }
        hasConfiguredAudioSession = true

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // Best-effort: `.ambient` still mixes without an active session.
        }
    }
}

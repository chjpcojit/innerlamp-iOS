# Requirements — Player

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full-screen player UI with in-memory playback state; no
audio, no track API, and the table-of-contents destination is not wired
Feature folder: `InnerLamp/Presentation/Scenes/Player/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Player
> feature. It documents the shipped behavior, including the in-memory playback
> state and the static catalog.

## User Story

As a practitioner, I want a full-screen audio player with track info, progress,
seek controls, playback speed, and a sleep timer, so that I can control sutra
recitation playback.

## Acceptance Criteria (EARS notation)

- WHEN the Player screen loads for a given sutra id, THE SYSTEM SHALL show the
  track title/subtitle, a progress bar with elapsed and remaining times, seek
  controls (±15s / +30s) around a play/pause button, and the speed + sleep-timer
  option rows.
- WHEN the user taps play/pause, THE SYSTEM SHALL toggle the playback state.
- WHEN the user taps the rewind/forward control, THE SYSTEM SHALL seek back 15s
  (clamped to 0) or forward 30s (clamped to the track duration).
- WHEN the user selects a playback speed, THE SYSTEM SHALL update the selected
  speed index.
- WHEN the user selects a sleep-timer option, THE SYSTEM SHALL update the
  selected option and its explanatory footnote.
- WHEN the user taps the back control, THE SYSTEM SHALL close the Player and
  return to the previous screen.
- WHEN the user taps the "Mục lục" pill, THE SYSTEM SHALL emit a
  table-of-contents event.

## Out of scope (this feature boundary, not backend work)

- The chapter list / SutraDetail screen (`.openTableOfContents` reaches a TODO
  in the coordinator).

## Pending (not yet implemented — see `tasks.md`)

- Real audio. Play/pause and seek only mutate in-memory state; `ILPlayerUseCaseImpl`
  notes real playback must drive `AVAudioPlayer` / a shared audio service once
  sutra audio files exist.
- A real track API. The catalog is a static 1-track mock (Kinh Pháp Cú) with a
  TODO to replace with `ILPlayerRepository` → `networkService`.

  > ⚠️ Not confirmed: the sutra-audio / track API contract(s) — no audio endpoint
  > in `Docs/Specs/API/openapi.yaml` v3.9. Blocks `tasks.md` Phase 3.

- The "Mục lục" destination is not wired (needs a navigation decision — the
  player is pushed on top of the reader/detail stack).

## Open questions (resolved during implementation)

- ~~Is the Player a leaf or a section coordinator?~~ → Leaf. `ILReaderCoordinator`
  (speed button) and `ILSutraDetailCoordinator` ("Mở trình phát") both push it;
  it has no delegate. Resolved during implementation (see `ILPlayerCoordinator`).

# Requirements — Reader

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — bilingual verse reading + playback UI with a static
catalog; no sutra API, no real audio, and font-size/share/download destinations
are not built
Feature folder: `InnerLamp/Presentation/Scenes/Reader/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Reader
> feature. It documents the shipped behavior, including the static catalog, the
> in-memory playback state, and the unimplemented destinations.

## User Story

As a practitioner, I want to read a sutra verse by verse in Vietnamese with an
English translation and a playback bar, so that I can chant along and follow the
recitation.

## Acceptance Criteria (EARS notation)

- WHEN the Reader screen loads for a given sutra id, THE SYSTEM SHALL show the
  sutra title/subtitle, a reading-progress bar, the current verse (Vietnamese +
  English translation), a preview of the next verse, and a playback bar.
- WHEN the user taps play/pause, THE SYSTEM SHALL toggle the playback state and
  update the now-playing label and icon.
- WHEN the user taps the "1.0×" speed control, THE SYSTEM SHALL open the
  full-screen player.
- WHEN the user taps "Chia sẻ câu kinh", THE SYSTEM SHALL emit a share event.
- WHEN the user taps "Tải để nghe offline", THE SYSTEM SHALL emit a download
  event.
- WHEN the user taps "Aa", THE SYSTEM SHALL emit a font-size event.
- WHEN the user taps the back control, THE SYSTEM SHALL close the Reader screen
  and return to the previous screen.

## Out of scope (this feature boundary, not backend work)

- The full-screen player — owned by the Player feature (`.openPlayer`).
- The font-size, share, and download screens — not built (each reaches a TODO in
  the coordinator).

## Pending (not yet implemented — see `tasks.md`)

- A real sutra/catalog API. `ILReaderUseCaseImpl` builds a static 1-sutra
  catalog (Kinh Pháp Cú) with a TODO to replace with `NetworkService`.
  (`tasks.md` Phase 3.)

  > ⚠️ Not confirmed: the sutra catalog / verse-content API contract(s) — no
  > reader endpoint in `Docs/Specs/API/openapi.yaml` v3.9. Blocks `tasks.md`
  > Phase 3.

- Real audio. `togglePlayPause` only flips the in-memory `isPlaying` flag; it is
  not wired to `ILPracticeSoundPlayer`/AVAudioPlayer (no recitation audio file).

- The font-size, share, and download destinations (all TODO).

## Open questions (resolved during implementation)

- ~~How is the sutra resolved when the id is unknown?~~ → Fallback to the first
  catalog sutra (Kinh Pháp Cú), the same mock-catalog fallback pattern as
  Library/Article. Resolved during implementation (see
  `Domain/UseCases/Reader/ILReaderUseCase.swift`).

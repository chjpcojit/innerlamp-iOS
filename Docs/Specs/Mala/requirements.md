# Requirements — Mala

Version: 1.0
Last updated: 2026-09-27
Status: implemented — full-screen bead counter with audio feedback; no
persistence, no network
Feature folder: `InnerLamp/Presentation/Scenes/Mala/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Mala feature.
> It documents the shipped behavior, including the memory-only counter.

## User Story

As a practitioner, I want a full-screen bead (tràng hạt) counter with a large
count, a progress bar, and the mantra, so that I can track my recitation and
receive feedback at milestones.

## Acceptance Criteria (EARS notation)

- WHEN the Mala screen opens, THE SYSTEM SHALL show a full-screen immersive
  counter with the bead count, a progress bar, the mantra ("Nam mô A Di Đà
  Phật"), and "Bắt đầu lại" / "Xong" buttons.
- WHEN the user taps or drags a bead, THE SYSTEM SHALL advance the count by one,
  wrapping back to 1 after 108, and play a soft click sound.
- WHEN the count reaches a quarter milestone (27, 54, 81), THE SYSTEM SHALL
  signal a light haptic feedback.
- WHEN the count reaches 108, THE SYSTEM SHALL count a completed round, play the
  bell sound, and signal the round-complete milestone.
- WHEN the user taps "Bắt đầu lại" (reset), THE SYSTEM SHALL reset the bead
  count to zero without touching the completed-round count.
- WHEN the user taps "Xong" or the back control, THE SYSTEM SHALL close the Mala
  screen and return to Home.

## Out of scope (this feature boundary, not backend work)

- Nothing is delegated to another feature — Mala is a self-contained leaf
  screen.

## Pending (not yet implemented — see `tasks.md`)

- Persistence. The bead/round count is memory-only and resets every open; it is
  not synced with the Home bead counter (both start from 0).

  > ⚠️ Not confirmed: whether Mala and Home should share a single persisted
  > bead count via a local Repository (Core Data / UserDefaults) — blocks the
  > persistence work.

- A user-facing volume / sound picker — audio is fixed (bead click + bell).

## Open questions (resolved during implementation)

- ~~Does audio belong in the Domain UseCase?~~ → No. `ILMalaUseCaseImpl` stays
  pure; `ILMalaViewModel` injects `ILPracticeSoundPlaying` and plays `playBead()`
  on every bead and `playBell()` on a completed round. Resolved during
  implementation (see `Core/Audio` and the README).

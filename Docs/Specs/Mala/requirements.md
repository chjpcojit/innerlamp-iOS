# Requirements — Mala

Version: 1.1
Last updated: 2026-10-03
Status: implemented — full-screen bead counter with audio feedback; no
persistence, no network
Feature folder: `InnerLamp/Presentation/Scenes/Mala/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Mala feature.
> It documents the shipped behavior, including the memory-only counter.
> v1.1 aligns it with the updated design handoff (`Docs/InnerLamp icon consistency/`).

## User Story

As a practitioner, I want a full-screen bead (tràng hạt) counter with a choice of
target (21 / 54 / 108 recitations), a progress bar, and the mantra, so that I
can track my recitation round by round and receive feedback at milestones.

## Acceptance Criteria (EARS notation)

- WHEN the Mala screen opens, THE SYSTEM SHALL show a full-screen immersive
  counter with a header ("Niệm Phật", subtitle "Vòng N · biến x / goal", and a
  "Xong" action), target chips (21 / 54 / 108 biến, default 108), a progress
  bar, the bead strand, the mantra ("Nam mô A Di Đà Phật"), and a "Bắt đầu lại"
  button.
- WHEN the user selects a target chip, THE SYSTEM SHALL set the round goal to
  that value and restart the count from zero, keeping the current round number.
- WHEN the user taps or drags a bead, THE SYSTEM SHALL advance the count by one
  and play a soft click sound, scattering gold sparks and an expanding ring from
  the strand center (a larger burst on every 27th bead).
- WHEN the count reaches a quarter milestone (goal / 4 — 27, 54, 81 for 108),
  THE SYSTEM SHALL signal a light haptic feedback.
- WHEN the count reaches the goal, THE SYSTEM SHALL stop counting, play the bell
  sound, signal the round-complete haptic, and show a "Tròn N biến" popup with
  "Niệm tiếp vòng mới" and "Xong".
- WHEN the user taps "Niệm tiếp vòng mới", THE SYSTEM SHALL dismiss the popup,
  reset the count to zero, and increment the round number.
- WHEN the user taps "Bắt đầu lại" (reset), THE SYSTEM SHALL reset the bead
  count to zero without changing the round number or the goal.
- WHEN the user taps "Xong" (header or popup) or the back control, THE SYSTEM
  SHALL close the Mala screen and return to Home.

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
- The design's per-bead wood-grain stripes are not drawn (see
  `Docs/Tech-Debt/Mala/TD-Mala-001-bead-grain-texture.md`).

## Open questions (resolved during implementation)

- ~~Does audio belong in the Domain UseCase?~~ → No. `ILMalaUseCaseImpl` stays
  pure; `ILMalaViewModel` injects `ILPracticeSoundPlaying` and plays `playBead()`
  on every bead and `playBell()` on a completed round. Resolved during
  implementation (see `Core/Audio` and the README).

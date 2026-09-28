# Requirements — MeditationSetup

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full-screen setup modal with duration selection; session
flow wired, Done/Journal screen not built; no network
Feature folder: `InnerLamp/Presentation/Scenes/MeditationSetup/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented
> MeditationSetup feature. It documents the shipped behavior, including the
> in-memory duration selection and the unimplemented Done/Journal destination.

## User Story

As a practitioner, I want to configure a meditation session (duration, bell
settings) before starting, so that I can begin a guided or silent session from
the lamp button or the Home suggested-session row.

## Acceptance Criteria (EARS notation)

- WHEN the user taps the central lamp button (or a meditation row on Home), THE
  SYSTEM SHALL present the MeditationSetup screen as a full-screen modal.
- WHEN the screen loads, THE SYSTEM SHALL show the duration options (5 / 12 / 20
  / 30 / 45 minutes, default 20), a bell-settings card (opening bell, interval
  bell, background sound — display-only), a posture tip card, and the CTA
  buttons.
- WHEN the user selects a duration, THE SYSTEM SHALL update the selected
  duration and the "Bắt đầu · N phút" CTA label.
- WHEN the user taps "Bắt đầu" (start), THE SYSTEM SHALL start a guided session
  with the selected duration.
- WHEN the user taps "Ngồi im lặng, không hướng dẫn" (silent), THE SYSTEM SHALL
  start a silent session with the selected duration.
- WHEN the user taps the ✕ close control, THE SYSTEM SHALL dismiss the practice
  flow modal and return to the previous screen.

## Out of scope (this feature boundary, not backend work)

- The MeditationSession screen — owned by the MeditationSession feature
  (`.startSession` pushes it).
- The Done / Journal screen — not built (the session-finish callback is a TODO).

## Pending (not yet implemented — see `tasks.md`)

- The Done / Journal screen. When a session finishes,
  `ILMeditationSetupCoordinator.meditationSessionDidFinish` logs a TODO and
  dismisses the whole practice-flow modal.
- Persistence of the selected duration — it resets to 20 minutes every open.
- The three bell rows are display-only (`kind: .value`, static); no bell/sound
  picker.

  > ⚠️ Not confirmed: whether bell/sound selection is in scope for this screen
  > or a global settings screen — blocks any bell-picker work.

- Opening from the Home "suggested session" row does not carry the row's
  content (title / teacher / duration) — the screen always shows static content
  and the default 20-minute selection.

## Open questions (resolved during implementation)

- ~~Is MeditationSetup a 5th tab or a modal?~~ → A full-screen **modal**, not a
  tab. The lamp button and the meditation row both present it (`.close` via ✕,
  matching the design's `showClose`). Resolved during implementation (see
  `ILMeditationSetupCoordinator`).

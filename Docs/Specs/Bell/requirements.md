# Requirements — Bell

Version: 1.0
Last updated: 2026-09-27
Status: implemented — full in-memory practice tool with real audio; no
persistence, no network
Feature folder: `InnerLamp/Presentation/Scenes/Bell/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Bell feature.
> It documents the shipped behavior, including the fact that session state is
> memory-only (no persistence).

## User Story

As a practitioner, I want a bell-and-wooden-fish tool to keep rhythm while
chanting, reciting, or prostrating, so that I can strike, auto-ring, and run a
steady or accelerating rhythm during practice.

## Acceptance Criteria (EARS notation)

- WHEN the Bell screen opens, THE SYSTEM SHALL show a full-screen immersive
  practice tool with a strike pad, five preset chips, a mode selector, a rhythm
  card, and a bottom action bar.
- WHEN the user taps the center pad, THE SYSTEM SHALL strike a wooden fish (in
  mõ mode) or ring a bell (in bell mode), play the corresponding sound, and
  increment the appropriate counter.
- WHEN the user taps a preset chip, THE SYSTEM SHALL apply that preset's mode /
  bpm / bell-interval / auto-bell milestone and stop any running playback.
- WHEN the user switches mode (Mõ / Chuông / Mõ + chuông), THE SYSTEM SHALL
  update the configuration, mark the session as customized, and stop playback.
- WHEN the user changes the "ring bell after every" milestone (off / 10 / 27 /
  108), THE SYSTEM SHALL update the auto-bell rule.
- WHEN the user taps the rate adjuster, THE SYSTEM SHALL nudge the rhythm —
  bell-only mode adjusts the gap by ±5 seconds (clamped 5…120), other modes
  adjust bpm by ±4 (clamped 40…160) — and re-time a running rhythm to the new
  interval.
- WHEN the user toggles play, THE SYSTEM SHALL start or stop a steady auto
  rhythm at the configured interval.
- WHEN the user taps the left action ("Dồn mõ" in mõ modes, "Đặt lại" in bell
  mode), THE SYSTEM SHALL either run a 16-strike accelerating roll ending in a
  bell, or reset the counters and stop playback.
- WHEN the user taps "Thỉnh chuông", THE SYSTEM SHALL ring a bell immediately.
- WHEN the user taps the back control, THE SYSTEM SHALL close the Bell screen
  and return to Home.

## Out of scope (this feature boundary, not backend work)

- Nothing is delegated to another feature — Bell is a self-contained leaf
  screen.

## Pending (not yet implemented — see `tasks.md`)

- Persistence. Session state (mode / preset / rhythm / counters) resets every
  time the screen opens; there is no local Repository (UserDefaults / Core
  Data). A persistence layer would be added alongside a real need.
- A per-session volume / sound picker. Strikes play real bundled audio
  (`bell_strike.m4a` + `mo_strike.m4a` through `ILPracticeSoundPlayer`), but
  there is no user-facing control for volume or choosing a different sound.

  > ⚠️ Not confirmed: whether sound selection / volume is in scope for Bell, or
  > deferred to a global settings screen — blocks any sound-picker work.

## Open questions (resolved during implementation)

- ~~Does audio belong in the Domain UseCase?~~ → No. The Domain layer stays
  framework-free; sound playback is a Presentation concern. `ILBellViewModel`
  injects `ILPracticeSoundPlaying` and routes every strike (tap / rhythm /
  roll) through it, keeping `ILBellUseCaseImpl` pure and unit-testable. Resolved
  during implementation (see `Core/Audio` and the README).

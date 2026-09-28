# Requirements — Talk

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; Dharma-talk content & audio stream contracts
unconfirmed
Feature folder: `InnerLamp/Presentation/Scenes/Talk/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a practitioner in the Library, I want to open a Dharma talk (Pháp thoại) so
that I can read its title/metadata, play or pause the talk, jump between its
chapters, and be offered a short meditation after listening.

## Acceptance Criteria (EARS notation)

- WHEN the Talk screen loads, THE SYSTEM SHALL show a transparent header over a
  dark hero with the talk's kicker ("PHÁP THOẠI · …"), title, speaker, duration,
  and play count.
- WHEN the user scrolls past 110 px, THE SYSTEM SHALL transition the transparent
  header to an opaque background.
- WHEN the user taps play/pause, THE SYSTEM SHALL control playback and show the
  current time and remaining time.
- WHEN the user drags the seek bar, THE SYSTEM SHALL seek within the talk.
- WHEN the user taps the 15s / 30s skip controls, THE SYSTEM SHALL jump forward
  or back by that amount.
- WHEN the screen renders the "Các phần" (chapters) list, THE SYSTEM SHALL show
  each chapter with its start time and title; tapping a chapter SHALL seek to
  that time.
- WHEN the screen renders the follow-up card ("Nghe xong, ngồi thiền 10 phút ·
  Quán niệm ân cha mẹ"), THE SYSTEM SHALL offer it; tapping it SHALL navigate to
  MeditationSetup.
- WHEN the user taps back, THE SYSTEM SHALL return to the Library.

## Out of scope (this feature boundary, not backend work)

- The Library featured Dharma-talk card that navigates here — owned by the
  Library feature (`Docs/Specs/Library/`).
- The full-screen Player (speed / sleep timer) and the Reader — separate
  features (`Docs/Specs/Player/`, `Docs/Specs/Reader/`).
- MeditationSetup — a separate feature reached from the follow-up card.

## Pending (not yet implemented — see `tasks.md`)

- Dharma-talk content API (title, speaker, chapters, audio URL, duration).

  > ⚠️ Not confirmed: the talk detail API contract (endpoint, response shape,
  > chapter list, error cases) — blocks `tasks.md` Phase 3.
- Audio stream / playback source.

  > ⚠️ Not confirmed: whether the audio is a streamed URL, a downloadable file,
  > or requires DRM — blocks real playback in `tasks.md` Phase 3.

## Open questions (resolved during implementation)

- <!-- none yet -->

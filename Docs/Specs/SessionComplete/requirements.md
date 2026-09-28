# Requirements — SessionComplete

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; session-record API unconfirmed
Feature folder: `InnerLamp/Presentation/Scenes/SessionComplete/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a practitioner finishing a meditation session, I want to record how I feel
and dedicate the merit (hồi hướng), so that the session is captured in my
journal and my streak continues.

## Acceptance Criteria (EARS notation)

- WHEN the SessionComplete screen loads after a session ends (naturally or via
  "Kết thúc sớm"), THE SYSTEM SHALL show the completion title ("Một thời khóa đã
  tròn đầy") and three stats: current streak, total practice hours, and people
  meditating together.
- WHEN the screen renders the mood prompt ("Tâm bạn lúc này thế nào?"), THE
  SYSTEM SHALL show four mood chips (Tĩnh lặng, Nhẹ nhàng, Còn tán loạn, Buồn
  ngủ) with single-select behavior; the selected chip is highlighted.
- WHEN the screen renders the dedication, THE SYSTEM SHALL show the default
  "Hồi hướng công đức cho · Cha mẹ hiện tiền" target.
- WHEN the user taps "Ghi vào nhật ký", THE SYSTEM SHALL save the session
  (duration, mood, dedication) and navigate to the Journal write screen.
- WHEN the user taps "Để sau", THE SYSTEM SHALL return to Home without saving the
  mood/dedication.

## Out of scope (this feature boundary, not backend work)

- The MeditationSession screen and its "Kết thúc sớm" action that navigate here
  — owned by the MeditationSession feature.
- The Journal write screen reached from "Ghi vào nhật ký" — owned by the Journal
  feature (`Docs/Specs/Journal/`).
- The session timer/bell itself.

## Pending (not yet implemented — see `tasks.md`)

- Session-record API (persist session + mood + dedication for the practice
  history / stats).

  > ⚠️ Not confirmed: whether the session is recorded locally-first (then
  > synced) or posted to a backend, and the contract if any — blocks
  > `tasks.md` Phase 3.

## Open questions (resolved during implementation)

- <!-- none yet -->

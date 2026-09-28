# Requirements — Reminder

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; local-only (no backend contract required)
Feature folder: `InnerLamp/Presentation/Scenes/Reminder/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a practitioner, I want to schedule a daily mindfulness bell reminder, so that
the app gently calls me back to my breath at a chosen time each day.

## Acceptance Criteria (EARS notation)

- WHEN the Reminder screen loads, THE SYSTEM SHALL show the intro ("Nhắc bạn trở
  về hơi thở") and the current main reminder time with up/down (▲▼) hour
  steppers.
- WHEN the user changes the hour, THE SYSTEM SHALL cycle 0–23 and update a
  contextual hint: before 11:00 → "Công phu khuya", 11:00–18:00 → "Một phút trở
  về hơi thở giữa ngày", after 18:00 → "Buông thư trước khi ngủ".
- WHEN the screen renders the weekday selector, THE SYSTEM SHALL show 7 day
  buttons (T2–CN) with toggle behavior.
- WHEN the user toggles days, THE SYSTEM SHALL update the summary to "05:30 · mỗi
  ngày" (every day) or "05:30 · N ngày mỗi tuần" (N days/week).
- WHEN the screen renders "Thời khóa khác", THE SYSTEM SHALL list additional
  preset schedule rows with independent switches.
- WHEN the user taps "Lưu chuông nhắc", THE SYSTEM SHALL schedule the local
  notification(s) and confirm.

## Out of scope (this feature boundary, not backend work)

- The Settings "Thời khóa" schedule card and the Stats "Giữ chuỗi ngày bằng
  chuông nhắc" card that navigate here.
- The Bell (chuông mõ) screen — a different feature (`Docs/Specs/Bell/`).
- Actual notification delivery — handled by the system / shared notification
  service, not this screen's UI.

## Pending (not yet implemented — see `tasks.md`)

- None requiring a backend — this is a local-only feature (UNUserNotificationCenter
  + local schedule).

## Open questions (resolved during implementation)

- <!-- none yet -->

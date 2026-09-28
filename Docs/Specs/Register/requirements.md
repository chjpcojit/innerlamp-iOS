# Requirements — Register

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; registration API unconfirmed
Feature folder: `InnerLamp/Presentation/Scenes/Register/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a practitioner browsing events and courses, I want to register for an event,
so that I can reserve my place and know the practical details.

## Acceptance Criteria (EARS notation)

- WHEN the Register screen loads, THE SYSTEM SHALL show the header ("Ghi danh"),
  the course/event name, and a details table (Thời gian · Địa điểm · Hướng dẫn).
- WHEN the screen renders "Số người cùng đi", THE SYSTEM SHALL offer four
  choices: Một mình, 2 người, 3 người, 4+ (single-select).
- WHEN the user changes the group size, THE SYSTEM SHALL update the confirm
  button label to "Ghi danh cho tôi" / "Ghi danh 2 người" / "Ghi danh 3 người" /
  "Ghi danh 4 người trở lên".
- WHEN the screen renders the note, THE SYSTEM SHALL show the event's note
  (e.g. "Khóa tu miễn phí. Xin đến trước 6:15…").
- WHEN the user taps the confirm button, THE SYSTEM SHALL submit the
  registration and return to the Events screen on success.

## Out of scope (this feature boundary, not backend work)

- The Events screen's "Ghi danh" / event taps that navigate here — owned by the
  Events feature.
- The "Đã ghi danh" tab in Events — owned by the Events feature.

## Pending (not yet implemented — see `tasks.md`)

- Registration API.

  > ⚠️ Not confirmed: the register API contract (endpoint, request/response
  > shape, capacity/error cases) — blocks `tasks.md` Phase 3.

## Open questions (resolved during implementation)

- <!-- none yet -->

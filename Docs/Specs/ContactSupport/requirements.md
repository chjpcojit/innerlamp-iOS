# Requirements — ContactSupport

Version: 1.0
Last updated: 2026-10-10
Status: not started — prospective; channels and submit API are mocked, contract unconfirmed
Feature folder: `InnerLamp/Presentation/Scenes/ContactSupport/`

> See `changelog.md` in this folder for the version history of this spec.
> Source of truth for business intent: `SRS.md` in this folder.

## User Story

As a practitioner, I want to reach the support team (ban hỗ trợ) by a direct
channel or by sending a request, so that I get help with my account, offerings,
temple data, or app problems.

## Acceptance Criteria (EARS notation)

- WHEN the screen loads, THE SYSTEM SHALL show the heading "Chúng tôi luôn lắng
  nghe", the response-hours text, three channels (Email, Hotline, Zalo OA), the
  request form and the "Câu hỏi thường gặp" shortcut.
- WHEN the user taps a channel row, THE SYSTEM SHALL launch the matching system
  action (compose email, dial hotline, open Zalo OA). (FR-001)
- WHEN the system cannot handle the channel action, THE SYSTEM SHALL tell the
  user the channel is unavailable. (FR-001)

  > ⚠️ Not confirmed: real email address, hotline number and Zalo OA link —
  > prototype values are placeholders; blocks release.

- WHEN the form is shown, THE SYSTEM SHALL offer the topics "Tài khoản", "Cúng
  dường", "Thông tin chùa", "Lỗi ứng dụng", "Góp ý" with "Tài khoản" selected.
  (FR-002)
- WHEN the user taps another topic, THE SYSTEM SHALL select only that topic.
  (FR-002)
- WHEN the user taps "Gửi yêu cầu" and the trimmed message has fewer than 10
  characters, THE SYSTEM SHALL show "Vui lòng mô tả ít nhất 10 ký tự." and not
  submit. (FR-003)
- WHEN the user edits the message while the error is shown, THE SYSTEM SHALL
  hide the error. (FR-003)

  > ⚠️ Not confirmed: maximum message length — no upper bound is enforced.

- WHEN the user taps "Gửi yêu cầu" with a valid message, THE SYSTEM SHALL submit
  the request and, on success, replace the form with the "Đã gửi yêu cầu" card
  showing the request code and chosen topic. (FR-004, FR-005)
- WHEN submission fails, THE SYSTEM SHALL show an error and keep the typed
  message. (FR-004)

  > ⚠️ Not confirmed: failure behavior (offline, server error, rate limit /
  > duplicate) — blocks error copy and retry design.

- WHEN the user taps "Gửi yêu cầu khác", THE SYSTEM SHALL show the form with an
  empty message and the default topic. (FR-005)
- WHEN the form is shown, THE SYSTEM SHALL state that the reply goes to the
  signed-in user's own phone number and the Notifications screen. (FR-005a)

  > ⚠️ Not confirmed: whether the reply really reaches Notifications and the
  > phone number — blocks the confirmation wording.

- WHEN the user taps "Câu hỏi thường gặp", THE SYSTEM SHALL open Help.
  (FR-006)
- WHEN the user taps back, THE SYSTEM SHALL pop the screen.

## Out of scope (this feature boundary, not backend work)

- The support ticketing backend and reply delivery to Notifications.
- The Settings row that opens this screen (Settings feature).
- The Help screen itself (`Docs/Specs/Help/`).

## Pending (not yet implemented — see `tasks.md`)

- Support-request API; the UseCase stub generates a local request code.

  > ⚠️ Not confirmed: support-request API (endpoint, payload, request-code
  > format, auth) — blocks `tasks.md` Phase 3.

- Persistence of an unsent draft.

  > ⚠️ Not confirmed: whether an unsent draft survives leaving the screen or app
  > relaunch — in-memory only for now.

## Open questions (resolved during implementation)

- ~~How is submit handled without an API?~~ → Stub in the UseCase, recorded as
  an Assumption (2026-10-10).
- ~~Are channel values real?~~ → Placeholders, kept as mock (2026-10-10).
- ~~Team name~~ → "Ban hỗ trợ" (2026-10-10).

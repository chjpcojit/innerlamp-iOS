# Requirements — Help

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; FAQ content source unconfirmed
Feature folder: `InnerLamp/Presentation/Scenes/Help/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a practitioner, I want to find answers to common questions, so that I can
resolve an issue myself without waiting for support.

## Acceptance Criteria (EARS notation)

- WHEN the Help screen loads, THE SYSTEM SHALL show the intro ("Bạn đang cần
  giúp điều gì?") and a search field.
- WHEN the user submits the search, THE SYSTEM SHALL open the Search screen.
- WHEN the screen renders the FAQ, THE SYSTEM SHALL show the list of questions
  (nghe không mạng, đổi điện thoại, gia hạn Sen Vàng, biên nhận cúng dường, tắt
  thông báo nhưng giữ chuông) as an accordion.
- WHEN the user taps a question, THE SYSTEM SHALL open it (gold border, rotated
  arrow); tapping it again or another question SHALL close the previous one so
  only one item is open at a time.
- WHEN the screen renders the footer, THE SYSTEM SHALL show "Vẫn chưa rõ? Ban hộ
  trì thường trả lời trong vòng một ngày".

## Out of scope (this feature boundary, not backend work)

- The Settings "Trợ giúp" row that navigates here — owned by the Settings feature.
- The Search screen opened from the help search field.

## Pending (not yet implemented — see `tasks.md`)

- FAQ content source.

  > ⚠️ Not confirmed: whether the FAQ is bundled static content or fetched from
  > a backend/CMS — blocks `tasks.md` Phase 3 (and whether a Domain/Repository
  > layer is needed at all).

## Open questions (resolved during implementation)

- <!-- none yet -->

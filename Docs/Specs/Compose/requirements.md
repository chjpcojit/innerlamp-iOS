# Requirements — Compose

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; post-publishing API unconfirmed
Feature folder: `InnerLamp/Presentation/Scenes/Compose/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a practitioner in the Sangha, I want to write and publish a share (bài chia
sẻ) to my community, so that I can contribute to the practice feed.

## Acceptance Criteria (EARS notation)

- WHEN the Compose screen loads, THE SYSTEM SHALL show the header (Đóng ·
  "Chia sẻ" · "Đăng"), the author's avatar + name, and an audience selector.
- WHEN the user taps the audience selector, THE SYSTEM SHALL cycle through three
  audiences: Đạo tràng Từ Quang → Bạn đồng tu → Chỉ mình tôi.
- WHEN the user types in the composer, THE SYSTEM SHALL accept free text.
- WHEN the user taps an attachment action, THE SYSTEM SHALL offer Thêm ảnh, Gắn
  câu kinh, and Gắn thời khóa.
- WHEN the user taps a tag chip (Thiền, Tụng kinh, Niệm Phật, Vu Lan), THE
  SYSTEM SHALL support multi-select.
- WHEN the user taps "Đăng lên đạo tràng", THE SYSTEM SHALL publish the post and
  navigate back to the post/Sangha feed.
- WHEN the user taps Đóng, THE SYSTEM SHALL dismiss Compose and return to Sangha
  without publishing.

## Out of scope (this feature boundary, not backend work)

- The Sangha screen's "viết bài" action that opens Compose (already referenced
  as `openCompose` in `ILSanghaNavEvent`) — owned by the Sangha feature.
- The Post screen and its comment feed — owned by the Post feature.

## Pending (not yet implemented — see `tasks.md`)

- Post-publishing API.

  > ⚠️ Not confirmed: the publish-post API contract (endpoint, audience/tag/
  > attachment shape, error cases) — blocks `tasks.md` Phase 3.

## Open questions (resolved during implementation)

- <!-- none yet -->

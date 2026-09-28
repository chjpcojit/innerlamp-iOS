# Requirements — Share

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; share-to-community behavior unconfirmed
Feature folder: `InnerLamp/Presentation/Scenes/Share/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a practitioner reading a sutra or article, I want to share a verse (câu kinh)
as a styled card, so that I can post it to my networks or copy the text.

## Acceptance Criteria (EARS notation)

- WHEN the Share screen loads, THE SYSTEM SHALL show a card preview of the verse
  with its kicker ("KINH PHÁP CÚ · KỆ 1") and a lamp motif.
- WHEN the user selects a background, THE SYSTEM SHALL immediately re-render the
  card with that background, text color, border, glow, and accent dot — from
  three options: Nền đêm, Giấy mộc, Sen hồng.
- WHEN the user taps a share destination, THE SYSTEM SHALL invoke the
  corresponding action — Zalo, Facebook, Đạo tràng, or Sao chép (copy to
  clipboard).
- WHEN the user taps "Sao chép", THE SYSTEM SHALL copy the verse text and confirm.
- WHEN the user taps "Đạo tràng", THE SYSTEM SHALL share the verse into the
  community feed.
- WHEN the user taps close (✕), THE SYSTEM SHALL dismiss the Share sheet and
  return to the originating screen (Reader or Article).

## Out of scope (this feature boundary, not backend work)

- The Reader and Article "Chia sẻ" actions that open this sheet.
- The rendered share-image asset generation, if the card is exported as an image
  — out of scope unless required by a destination.
- The Đạo tràng feed itself (owned by Sangha / Post).

## Pending (not yet implemented — see `tasks.md`)

- Share-to-community (Đạo tràng) posting.

  > ⚠️ Not confirmed: whether "Đạo tràng" posts to the community feed via an
  > API, or is a local placeholder action — blocks `tasks.md` Phase 3.

## Open questions (resolved during implementation)

- <!-- none yet -->

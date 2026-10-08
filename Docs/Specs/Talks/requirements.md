# Talks — Requirements (v1.1)

Feature folder: `InnerLamp/Presentation/Scenes/Talks/`

## User Story

As a practitioner, I want to see every Dharma talk in one list and open one, so that I can pick a
talk beyond the featured one on the Library tab.

## Acceptance Criteria (EARS)

- WHEN the user taps the "Pháp thoại" quick-access tile in Library, THE SYSTEM SHALL push the
  Talks list screen.
- WHEN the screen loads, THE SYSTEM SHALL show one card per catalog talk — type icon tile
  (audio / video / text), eyebrow (season uppercased, else BÀI GIẢNG / VIDEO / BẢN GHI), title,
  "speaker · N phút | N phút đọc | Video" — and a "N bài giảng" subtitle.
- WHEN a talk has a saved listen position, THE SYSTEM SHALL show a progress bar with
  "Đang nghe dở · N%".
- WHEN the user selects a filter chip (Tất cả / Nghe / Xem / Đọc, each with its count), THE SYSTEM
  SHALL show only talks of that type; the subtitle keeps the total.
- WHEN the user taps a card, THE SYSTEM SHALL open the Talk screen for that talk `id`.
- WHEN the user taps back, THE SYSTEM SHALL pop the screen and return to Library.
- IF the catalog is empty, THEN THE SYSTEM SHALL show the empty state instead of the list.

## Out of scope

- Search, sort, pagination, download state.
- Talk detail/player (owned by `Docs/Specs/Talk/`).

## ⚠️ Not confirmed

- ⚠️ Not confirmed: the video and text detail screens (`talkYt`, `talkText`) are not built, so
  every row opens the audio Talk screen. See `Docs/Tech-Debt/Talks/TD-Talks-002-detail-variants.md`.
- ⚠️ Not confirmed: catalog list API contract. See
  `Docs/Tech-Debt/Talks/TD-Talks-001-mock-catalog.md`.

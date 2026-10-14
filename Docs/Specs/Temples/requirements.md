# Requirements — Temples ("Tất cả chùa")

Version: 1.0
Last updated: 2026-10-11
Status: in-progress — UI + logic done, build verified; unit tests written but not run; on-device QA pending
Feature folder: `InnerLamp/Presentation/Scenes/Temples/`

> See `changelog.md` in this folder for the version history of this spec.

> Source: prototype screen `temples` ("Tất cả chùa") in `Docs/innerlamp-project/`, reached from the
> "Xem tất cả" link of the Home block "Chùa Việt Nam".

## User Story

As a user, I want to browse the whole temple directory from the Home page so that I can find and open
any temple, not just the few featured in the Home carousel.

## Acceptance Criteria (EARS notation)

- WHEN the user views the Home block "Chùa Việt Nam", THE SYSTEM SHALL show the link "Xem tất cả" in
  place of the former "Tìm chùa".
- WHEN the user taps "Xem tất cả", THE SYSTEM SHALL open the "Chùa Việt Nam" list screen.
- WHEN the screen opens, THE SYSTEM SHALL load every temple of the directory and show the total as the
  subtitle ("N ngôi chùa"), regardless of the active search / region filter.
- WHEN the user types in the search field, THE SYSTEM SHALL list only temples whose name or address
  contains the text, ignoring case and diacritics.
- WHEN the user selects a region chip, THE SYSTEM SHALL list only temples of that region ("Tất cả" = no
  filter); search and region combine.
- WHEN no temple matches, THE SYSTEM SHALL show "Không tìm thấy chùa" with a hint to change the keyword
  or region.
- WHEN the user taps a temple card, THE SYSTEM SHALL open that temple's page.
- IF loading fails, THEN THE SYSTEM SHALL show an error (offline has its own title) with "Thử lại".

## Out of scope / not built

- "Đề xuất" action of the prototype nav bar (TD-Temples-001).
- "Tây Nguyên" region chip of the prototype (AS-Temples-001).

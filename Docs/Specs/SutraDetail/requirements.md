# Requirements — SutraDetail

Version: 1.2
Last updated: 2026-10-07
Status: in-progress — loads the real sutra from `GET /v1/sutras/{id}`; Reader/Player still mock, no audio /
progress data, Download destination not built
Feature folder: `InnerLamp/Presentation/Scenes/SutraDetail/`

> See `changelog.md` in this folder for the version history of this spec.

> v1.2 (2026-10-07): the screen now loads one sutra from the backend. Sections of
> the design that the API cannot feed (audio, narrator, reading progress,
> per-section duration) are recorded in `Docs/Tech-Debt/SutraDetail/`.

## User Story

As a practitioner, I want to see a sutra's overview (title, narrator, chapter
count, description, and table of contents) before chanting, so that I can
understand the text and jump into the reader or player.

## Acceptance Criteria (EARS notation)

- WHEN the SutraDetail screen loads for a given sutra id, THE SYSTEM SHALL call
  `GET /v1/sutras/{id}` and show a pinned theme-aware header (back + "Tải về máy"), a
  hero (kicker = kind + tradition, title, italic original name, meta line
  "N dòng · duration", purpose chips), a description line ("collection · reference"),
  the translator / source / license lines, and — only when the sutra has `sections` — a
  table of contents with each section's line count.
- WHEN the request fails (including `404 SUTRA_NOT_FOUND`), THE SYSTEM SHALL show the error.
- WHEN the page is scrolled more than 110pt, THE SYSTEM SHALL show a hairline
  under the pinned header (no line at the top of the page).
- THE SYSTEM SHALL label the primary CTA "Đọc kinh", hide the round play button and hide the
  reading-progress card (the API has no audio or progress).
- WHEN the user taps the CTA or a section in the table of contents, THE SYSTEM SHALL open the
  Reader screen for the same sutra id.
- WHEN the user taps the play button in the bottom CTA bar, THE SYSTEM SHALL open the full-screen
  Player for the same sutra.
- WHEN the user taps "Tải về máy" (download), THE SYSTEM SHALL emit a download event.
- WHEN the user taps the back control, THE SYSTEM SHALL close the SutraDetail
  screen and return to the previous screen.

## Out of scope (this feature boundary, not backend work)

- The Reader screen — owned by the Reader feature (`.openReader`).
- The full-screen Player — owned by the Player feature (`.openPlayer`).
- The Download screen — not built (`.download` reaches a TODO in the
  coordinator).

## Pending (see `tasks.md`)

- Reader / Player still run on mock catalogs and ignore server ids; Library's "Kinh Pháp Cú" tile has
  no server match — TD-SutraDetail-003.
- No audio, narrator, reading progress or per-section duration from the API — TD-SutraDetail-002.
- The Download destination (`.download` is a TODO).
- Description / meta / license presentation is an assumption — AS-SutraDetail-001.

## Open questions (resolved during implementation)

- ~~Is `.openPlayer` wired or a TODO?~~ → Wired. `ILSutraDetailCoordinator`
  handles `.openPlayer` by pushing `ILPlayerCoordinator` (the README's "TODO"
  note for `.openPlayer` is stale — only `.download` is a real TODO). Resolved
  2026-09-27 by reading the coordinator while writing this spec.

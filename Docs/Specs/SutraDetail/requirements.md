# Requirements — SutraDetail

Version: 1.4
Last updated: 2026-10-11
Status: in-progress — loads the real sutra from `GET /v1/sutras/{id}`; Reader/Player still mock, no audio /
progress data, Download destination not built
Feature folder: `InnerLamp/Presentation/Scenes/SutraDetail/`

> See `changelog.md` in this folder for the version history of this spec.

> v1.4 (2026-10-11): product decision — the detail screen shows **all** information the API returns
> (confirmed by the product owner). `summary` is displayed when present and simply hidden while the backend
> has none (it will be seeded later). Resolves the v1.3 ⚠️ item; two details remain unconfirmed below.

> v1.3 (2026-10-11): re-checked with the backend — the HTTP contract is unchanged, but the API *does*
> expose a `summary` (AI-drafted, unreviewed, currently empty) and bibliographic fields the screen does
> not show yet. Whether to display them is ⚠️ Not confirmed — AS-SutraDetail-002.

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
- WHEN the sutra has a non-empty `summary`, THE SYSTEM SHALL show it as an introduction block ("Giới thiệu")
  below the hero; WHEN `summary` is empty, THE SYSTEM SHALL hide the block entirely (no placeholder).
- WHEN the sutra has any of the other-language `titles`, `author`, `han_translator` (+
  `han_translation_year`), `reference_note` or `deities[]` (`deity_id`, `role`, `name_vi`), THE SYSTEM SHALL
  show an information block ("Thông tin") with one labelled row per non-empty value (each deity row is
  labelled by its role: speaker / subject / mentioned), and SHALL hide every row whose value is empty or
  `null`. `original_title` is shown in the hero (italic name).
  > ⚠️ Not confirmed: final row labels / order and whether a deity row should open the Deity screen —
  > blocks the final copy and deity navigation; shown as plain text with default Vietnamese labels
  > until confirmed (AS-SutraDetail-002).
- WHEN the preferred translation has `variant`, `license`, `license_note`, `source_name`, `source_url` or
  `note`, THE SYSTEM SHALL show them in a "Bản dịch & giấy phép" block, rendering `source_url` as a tappable
  `http(s)` link and hiding each empty value.
- WHEN the sutra has a non-empty `review_status` (only `UNREVIEWED` exists today; the backend advises
  treating any other value as unreviewed), THE SYSTEM SHALL show a short "Lưu ý" notice that the content
  is not yet reviewed.
  > ⚠️ Not confirmed: the notice wording and the value that will mean "reviewed" — blocks the final copy;
  > any non-empty status shows the notice until confirmed (AS-SutraDetail-002).
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
- Show all API fields (v1.4) — implemented 2026-10-11 against the backend's confirmed JSON (see
  `tasks.md` Phase 6). Not shown: deity `thumbnail_url` (no design for it), audio (`audio_url` is `""`
  everywhere) — AS-SutraDetail-002.

## Open questions (resolved during implementation)

- ~~Is `.openPlayer` wired or a TODO?~~ → Wired. `ILSutraDetailCoordinator`
  handles `.openPlayer` by pushing `ILPlayerCoordinator` (the README's "TODO"
  note for `.openPlayer` is stale — only `.download` is a real TODO). Resolved
  2026-09-27 by reading the coordinator while writing this spec.

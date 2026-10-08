# Requirements — Articles

Version: 1.1
Last updated: 2026-09-30
Status: in-progress — list screen reads the articles API; device QA pending
Feature folder: `InnerLamp/Presentation/Scenes/Articles/`

> See `changelog.md` in this folder for the version history of this spec.

> Written retroactively from the implemented "All articles" screen, plus the
> backend contract confirmed on 2026-09-30. The canonical contract lives in
> `Docs/Specs/Article/design.md` → "API contract".

## User Story

As a practitioner, I want to browse every "Phật pháp hay" article and open one,
so that I can find something to read beyond the five shown on Home.

## Acceptance Criteria (EARS notation)

- WHEN the Articles screen loads, THE SYSTEM SHALL fetch the first page
  (`GET /v1/articles?page=1`) and show its rows (category, title, author, read
  time) with the "loaded / total" subtitle.
- WHEN the user scrolls near the end of the list AND more pages exist
  (`page < total_pages`), THE SYSTEM SHALL fetch the next page and append its
  rows, showing the load-more footer while the request is in flight.
- WHEN the last page has been loaded (`page >= total_pages`) or a page comes
  back empty, THE SYSTEM SHALL stop requesting further pages.
- IF a page request fails, THEN THE SYSTEM SHALL keep the rows already loaded,
  stop the load-more spinner, and show a localized error.
- WHEN the user taps a row, THE SYSTEM SHALL open the Article detail screen for
  that article's `id`.
- WHEN the user taps back, THE SYSTEM SHALL close the screen and return to Home.

## Out of scope

- Search, category filter, sort — the API supports none (`/v1/articles` takes
  only `page`).
- The Article detail content (owned by the `Article` feature/spec).

## Pending (not yet implemented — see `tasks.md`)

- Device QA against the dev backend (scroll to load pages 2 and 3, offline
  error, tap-through to detail).
- Client page size is fixed by the server (10); the design handoff's "20 of 60"
  no longer applies.

## Open questions (resolved)

- ~~Pagination style?~~ → Page-based, 1-based, fixed page size 10, `total` and
  `total_pages` always present; a page past the end is `200` with empty items.
  Confirmed by [BE-Developer] 2026-09-30.

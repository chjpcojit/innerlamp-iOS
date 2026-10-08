# Requirements — Photos

Version: 1.2
Last updated: 2026-10-07
Status: implemented against the real gallery API (`GET /v1/gallery`); build
passes, unit tests written but not run, not checked on a device
Feature folder: `InnerLamp/Presentation/Scenes/Photos/`

> See `changelog.md` in this folder for the version history of this spec.

> v1.0 was written retroactively from the Photos feature built on a static
> mock catalog. v1.1 replaces the catalog with the real gallery API, confirmed by
> the backend team on 2026-10-06 (see `design.md` → "API contract").

## User Story

As a practitioner, I want to browse a gallery of beautiful temple photos
filtered by category, so that I can explore temples, Buddha statues, meditation
scenes, and festivals.

## Acceptance Criteria (EARS notation)

- WHEN the Photos screen loads, THE SYSTEM SHALL request the first page of the
  gallery for all categories and show the photos in a 2-column grid with a
  horizontally scrollable category filter (Tất cả / Chùa / Tượng Phật / Cảnh
  thiền / Lễ hội) and a header subtitle showing the total photo count.
- WHEN a photo cell is shown, THE SYSTEM SHALL load its thumbnail image and keep
  a neutral placeholder tile until the image has loaded or if it fails to load.
- WHEN the user scrolls near the bottom of the grid and more pages exist, THE
  SYSTEM SHALL load the next page and append only the new photos, without
  reloading the photos already shown.
- WHILE a page is loading, THE SYSTEM SHALL show the loading footer; WHEN the
  last page has been loaded, THE SYSTEM SHALL show the end-of-list footer.
- WHEN the user selects a category filter, THE SYSTEM SHALL highlight the chip
  at once, request the first page for that category while the current photos
  stay visible, then crossfade the grid to the new photos, scroll it to the top
  and update the subtitle to the server total for that category.
- IF loading the first page of a newly selected category fails, THEN THE SYSTEM
  SHALL keep the current photos, move the chip selection back to the category
  they belong to, and show the error.
- WHEN the user selects "Tất cả", THE SYSTEM SHALL request the first page for
  all categories.
- IF a page request fails, THEN THE SYSTEM SHALL keep the photos already loaded
  and show the error message (offline / generic).
- WHEN the user taps the back control, THE SYSTEM SHALL close the Photos screen
  and return to Home.

## Out of scope (this feature boundary, not backend work)

- The photo lightbox / detail view — now its own feature: `Docs/Specs/PhotoViewer/`
  (grid tiles open it).
- (Home's "Ảnh chùa đẹp" strip now reads `GET /v1/gallery/top` — see
  `Docs/Specs/Home/`.)

## Pending (not yet implemented — see `tasks.md`)

- Author / license attribution. The backend serves CC BY / CC BY-SA images and
  asks that author + license (+ `source_url`) be shown. That needs the detail
  endpoint and a detail UI, which are out of scope here; recorded as tech debt
  (`Docs/Tech-Debt/Photos/TD-Photos-001-*`).
- Visual QA (grid, scrollable chips, dark mode, real device) has not been
  verified — only build + unit tests.

## Open questions (resolved)

- ~~Is "Tất cả" a category?~~ → No, it is a filter (`selectedCategory == nil`).
  Resolved during implementation (see `Presentation/Scenes/Photos/README.md`).
- ~~The photos API / asset source~~ → Resolved 2026-10-06: the backend serves
  `GET /v1/gallery` (REST, public, 20 per page, `type` filter) on dev. The
  four `type` values map 1:1 onto the existing four categories. Impact: the
  static catalog, `getInitialState()` / `selectCategory` / `filteredPhotos`
  and the mock copy are replaced; `design.md` and `tasks.md` updated.
- ~~Real image dimensions~~ → The API returns no width/height. Resolved with an
  assumption: every tile uses a fixed 4:3 ratio (`Docs/Assumptions/Photos/
  AS-Photos-001-*`); 12 sampled thumbnails (2026-10-06) are all landscape
  (500x281 – 500x466).

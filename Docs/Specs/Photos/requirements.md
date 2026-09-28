# Requirements — Photos

Version: 1.0
Last updated: 2026-09-27
Status: implemented — 2-column masonry gallery with category filter on a static
mock catalog; no photos API
Feature folder: `InnerLamp/Presentation/Scenes/Photos/`

> See `changelog.md` in this folder for the version history of this spec.

> This spec is written retroactively from the already-implemented Photos
> feature. It documents the shipped behavior, including the static mock
> catalog.

## User Story

As a practitioner, I want to browse a gallery of beautiful temple photos
filtered by category, so that I can explore temples, Buddha statues, meditation
scenes, and festivals.

## Acceptance Criteria (EARS notation)

- WHEN the Photos screen loads, THE SYSTEM SHALL show a 2-column masonry grid
  of 12 photos with a horizontally scrollable category filter (Tất cả / Chùa /
  Tượng Phật / Cảnh thiền / Lễ hội) and a header subtitle showing the photo
  count.
- WHEN the user selects a category filter, THE SYSTEM SHALL show only the
  photos in that category and update the subtitle to reflect the filtered count
  and category.
- WHEN the user selects "Tất cả", THE SYSTEM SHALL show all photos.
- WHEN the user taps the back control, THE SYSTEM SHALL close the Photos screen
  and return to Home.

## Out of scope (this feature boundary, not backend work)

- A photo lightbox / detail view — the prototype has no markup for one, so
  photo cells are currently not tappable.

## Pending (not yet implemented — see `tasks.md`)

- Real photos. Photo cells render a warm tint + category label as a placeholder;
  there are no real images yet.

  > ⚠️ Not confirmed: the photos API / asset source — the catalog is static
  > (`Component.PHOTOS` from the design handoff), and real images are expected
  > from the product side. Blocks `tasks.md` Phase 3.

- The per-photo display height (`imageHeight`) is a provisional ratio from the
  prototype; it should be replaced by real image dimensions/aspect ratio once
  real photos exist.

- Visual QA (masonry grid, scrollable chips, dark mode) has not been verified
  on simulator/device yet — only build + unit tests pass.

## Open questions (resolved during implementation)

- ~~Is "Tất cả" a category?~~ → No, it is a filter, represented by
  `selectedCategory == nil` on the entity (not a 5th `ILPhotosCategory` case).
  Resolved during implementation (see `Presentation/Scenes/Photos/README.md`).

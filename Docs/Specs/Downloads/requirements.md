# Requirements — Downloads

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; catalog/download-list contract unconfirmed
Feature folder: `InnerLamp/Presentation/Scenes/Downloads/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a practitioner who sometimes practices offline, I want to see and manage the
content I have downloaded to my device, so that I know what is available without
a connection and how much storage it uses.

## Acceptance Criteria (EARS notation)

- WHEN the Downloads screen loads, THE SYSTEM SHALL show a header with the item
  count and total size (e.g. "Nghe không cần mạng · 8 mục · 412 MB").
- WHEN the screen renders the storage bar, THE SYSTEM SHALL show used vs total
  capacity with colored segments per content type (Pháp thoại / Kinh văn / Nhạc
  thiền).
- WHEN the screen renders the list, THE SYSTEM SHALL show each downloaded item
  with its name, size · duration, and a state indicator: "Đã tải" (downloaded),
  a percentage in progress, or "Chờ Wi-Fi" (waiting for Wi-Fi).
- WHEN a download is in progress, THE SYSTEM SHALL show a progress bar with the
  current percentage.
- WHEN the user taps a fully downloaded item, THE SYSTEM SHALL open it (a sutra
  → Reader, a talk → Player).
- WHEN the user taps back, THE SYSTEM SHALL return to Settings (or the screen
  that opened Downloads).

## Out of scope (this feature boundary, not backend work)

- The Settings row "Tải về" and the Reader/SutraDetail "Tải về" actions that
  navigate here — owned by those features.
- The actual download engine / background transfer — assumed to be a shared
  Core concern; this feature only renders and manages its list.
- The offline/error state screens.

## Pending (not yet implemented — see `tasks.md`)

- Download-list / catalog source — where the list of downloadable items and
  their URLs come from.

  > ⚠️ Not confirmed: whether the downloadable catalog is a backend API, bundled
  > metadata, or derived from local download records — blocks `tasks.md`
  > Phase 3.

## Open questions (resolved during implementation)

- <!-- none yet -->

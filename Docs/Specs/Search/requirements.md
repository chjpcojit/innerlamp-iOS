# Requirements — Search

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; catalog search & content-request API contracts
unconfirmed
Feature folder: `InnerLamp/Presentation/Scenes/Search/`

> See `changelog.md` in this folder for the version history of this spec.

## User Story

As a practitioner browsing the Library, I want to search across sutras, guided
meditations, and Dharma talks, so that I can find a specific piece of content
quickly, and request a sutra the library does not have when I find nothing.

## Acceptance Criteria (EARS notation)

- WHEN the Search screen loads, THE SYSTEM SHALL show a search field pre-filled
  with the current keyword, a "Hủy" (cancel) action, and result tabs with
  counts (Tất cả / Kinh / Pháp thoại).
- WHEN the user types a keyword and submits, THE SYSTEM SHALL query the content
  catalog and show results grouped into a "Kết quả nổi bật" (featured) card and
  a "Trong thư viện" (in-library) list.
- WHEN the search returns results, THE SYSTEM SHALL update each tab's count and
  render the matching items with their type, title, and metadata (audio,
  duration).
- WHEN the user taps a result, THE SYSTEM SHALL navigate to the corresponding
  screen: a sutra result → Reader, a Dharma talk result → Talk, a guided
  meditation result → MeditationSetup.
- WHEN the search returns no results, THE SYSTEM SHALL show the empty state
  (IL-State "Chưa tìm thấy bản kinh này") with a "Gửi yêu cầu bản kinh"
  (request this sutra) action and a "Có thể bạn đang tìm" suggestions list.
- WHEN the user taps "Gửi yêu cầu bản kinh", THE SYSTEM SHALL submit a content
  request for the searched keyword and confirm to the user.
- WHEN the user taps "Hủy" or back, THE SYSTEM SHALL return to the screen that
  opened Search (Library or Help).

## Out of scope (this feature boundary, not backend work)

- The Library catalog, featured Dharma-talk card, and the search entry field on
  the Library screen — owned by the Library feature (`Docs/Specs/Library/`).
- The Reader, Talk, and MeditationSetup screens that results navigate to.
- The Help screen's own search entry that also opens Search.

## Pending (not yet implemented — see `tasks.md`)

- Catalog search API — the backend endpoint and response shape for
  cross-category content search.

  > ⚠️ Not confirmed: the search API contract (endpoint, request params, result
  > shape, pagination, error cases) — blocks `tasks.md` Phase 3.
- Content-request API ("gửi yêu cầu bản kinh").

  > ⚠️ Not confirmed: whether a content-request endpoint exists and its shape —
  > blocks the request-sutra flow in `tasks.md` Phase 3.

## Open questions (resolved during implementation)

- <!-- none yet -->

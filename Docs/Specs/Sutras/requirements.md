# Sutras — Requirements (v1.2)

Source: design handoff prototype screen `sutras` ("Kinh sách") + backend `GET /v1/sutras`. Entry:
Library quick-access tile "Kinh sách" and the "Kinh sách" view-all link.

- REQ-1: When the user opens the screen, the system shall load the first page (20 sutras) of
  `GET /v1/sutras` and list each with title, original name, duration (when known), translator ·
  tradition, and purpose badges (daily chant + purposes).
- REQ-2: When the list is scrolled near the bottom and more pages exist, the system shall load and
  append the next page without rebuilding the existing rows, showing a loading footer meanwhile and an
  end note once everything is loaded.
- REQ-3: When the user selects a category chip (All, Daily chant, one of the 10 purposes, one of the 3
  traditions), the system shall restart from page 1 with the matching server filter. A response to a
  superseded filter shall be dropped.
- REQ-4: When the user selects a length chip (any, up to 5 / 15 / 30 minutes), the system shall restart
  from page 1 with `max_minutes`.
- REQ-5: When the user pauses typing in the search field (300 ms debounce), the system shall restart from
  page 1 with `q=<keyword>` (trimmed, at most 100 characters; a blank keyword sends no `q`). The server
  matches title (any language) / collection / reference, ignoring case and diacritics (e.g. "dai bi"
  finds "Chú Đại Bi"), combined with the chips. A response to a superseded keyword shall be dropped.
- REQ-6: The system shall show "N bản kinh" (N = server total; "N bản kinh phù hợp" while a keyword is active) and an empty state only when nothing matches and nothing is loading.
- REQ-7: When a request fails, the system shall keep the rows already loaded, clear the loading footer
  and show the error.
- REQ-8: When the user taps a card, the system shall open Chi tiết bài kinh for that sutra's server id.
- REQ-9: When a sutra's `audio_url` is non-empty, the system shall show the "Có audio" badge on its card
  (an empty or missing `audio_url` means no audio).
- REQ-10: While the search field has text, the system shall show a round "×" at its trailing edge; tapping it empties the field and, after the same debounce, restores the unfiltered list.

Open items (see `Docs/Tech-Debt/Sutras/`, `Docs/Assumptions/Sutras/`):
- TD-Sutras-002 — "downloaded" badge never shown (no Downloads feature); the audio badge now follows `audio_url`
  (no sutra has audio yet).
- AS-Sutras-001..003 — search scope, chip set / thresholds, title and translation preference.
- Resolved: TD-Sutras-003 (server-side search via `q`, 2026-10-07).
- ⚠️ Not confirmed: whether combining filters (purpose + tradition + length) is wanted; today the category
  chips are mutually exclusive and combine only with the length chip.

# Requirements — Calendar

Version: 1.1
Last updated: 2026-10-15
Status: in-progress — festival calendar, event detail and Home's events block are built against `GET /v1/calendar/events` (signed-in only, build-verified, tests not run); product spec v1.1 alignment pending: server-only Rằm / Mùng Một, filters by group, 2100 limit, retry and device copy, hidden empty sections, home-block window and tiers, product vectors; public route and major mark wait on the backend (`tasks.md` Phase 4–9)
Feature folders: `InnerLamp/Presentation/Scenes/Festivals/` (festival calendar), `InnerLamp/Presentation/Scenes/FestivalDetail/` (event detail), the events block of `InnerLamp/Presentation/Scenes/Home/`
Product spec: innerlamp-be `docs/product/calendar/product.md` @ v1.1
Contract: innerlamp-be `docs/specs/api/openapi.yaml` @ 0eb7d1f (info.version 1.0.0; `GET /v1/calendar/events` last changed in a8a016b — still bearer-only, no `is_major` / `sort_order` / `recurrence`). Planned shape: innerlamp-be `docs/specs/features/calendar/requirements.md` + `design.md` v3.0 (E4, E13, E17, E22, E23), not implemented yet (backend `tasks.md` Phase 14–18; the contract update is Phase 18)
Implements: BR-CAL-05, BR-CAL-08, BR-CAL-09, BR-CAL-10, BR-CAL-11, BR-CAL-12, BR-CAL-13, BR-CAL-14, BR-CAL-15, FR-CAL-001..008, NFR-CAL-03
Not on iOS: BR-CAL-01…04, BR-CAL-06, BR-CAL-07, BR-CAL-16, FR-CAL-010, NFR-CAL-01, NFR-CAL-02 (Backend only); FR-CAL-009 (Website only, product §3.6)

> See `changelog.md` in this folder for the version history of this spec.

iOS platform spec (layer 2) of the Buddhist events calendar ("Sự kiện Phật giáo", product slug
`calendar`). Product behavior — which events exist, how their dates are found, both dates, groups, major
events, order, countdown, content format, what the home block shows, offline reading — lives in the
product spec and is **not** restated here; this file only says how the iOS app implements those
`BR-CAL-*` / `FR-CAL-*`. Written retroactively on 2026-10-15 from the code shipped on 2026-10-11/12
(Festivals, FestivalDetail, Home events carousel); it replaces `Docs/Specs/FestivalDetail/` v1.0 and
the calendar parts of `Docs/Specs/Home/` v1.11.

> Layout source: the design prototype `InnerLamp Prototype.dc.html` (product spec §1.5), screens
> `festVals` ("Lịch lễ Phật giáo") and `festDetail` ("Chi tiết ngày lễ"), plus Home item 4. Where the
> prototype and the product spec differ (filters, group labels, hidden sections, home-block rows), the
> product spec wins.

## User Story

As a practitioner, signed in or not, I want to see on my iPhone when this year's and the coming years'
Buddhist festivals, Rằm and Mùng Một fall — in both the solar and the lunar calendar — and what they
mean, so that I can prepare without working out the lunar calendar myself.

## Constraints from the product spec

- **The server computes every date** (product §2.5, BR-CAL-01…07): the app shows the occurrences the
  backend returns and computes no event date of its own, Rằm and Mùng Một included (BR-CAL-05). The
  app computes only the countdown (BR-CAL-13), the filters and the home block (BR-CAL-15), and orders
  locally only where it merges or tiers occurrences (BR-CAL-12).
- **Public** (FR-CAL-001): nothing in this feature is personal; a guest sees exactly what a signed-in
  user sees.
- **Offline read** (FR-CAL-007, product §3.5): the last loaded copy of a year stays on the device and
  holds no personal data.
- **Years** (FR-CAL-004, product §2.5): the current year onward, up to 2100.
- No platform variance for iOS in product §3.6; FR-CAL-009 (previous / next) is website only — the app
  goes back to the list.

## Acceptance Criteria (EARS notation)

### Access

1. WHEN a guest or a signed-in user opens the festival calendar, an event detail or Home's events block, THE SYSTEM SHALL request `GET /v1/calendar/events` with no `Authorization` header and no `X-API-Key`, and SHALL show both users the same occurrences in the same order, with no sign-in prompt. (FR-CAL-001)

    > ⚠️ Not confirmed (contract): `openapi.yaml` still lists `/v1/calendar/events` as bearer-only; the public route is planned in backend design v3.0 (E4, E22) and lands in the contract with backend Phase 18 — blocks criterion 1 and `tasks.md` Phase 6 "Public route"; hand-off to the backend (already planned there).

### Festival calendar ("Lịch lễ Phật giáo")

2. WHEN the user taps "Tất cả" or "+N sự kiện khác" in Home's events block, "Lịch lễ" on the Sangha (temple) tab, or the festival link on a deity page, THE SYSTEM SHALL push the festival calendar. (FR-CAL-006, platform)
3. WHEN the festival calendar opens, THE SYSTEM SHALL load the current year — the year of today in Vietnam time (`Asia/Ho_Chi_Minh`) — list its occurrences grouped by solar month from January to December in the order the server sent them, and scroll once so the current month is at the top. (FR-CAL-002, BR-CAL-02, BR-CAL-12)
4. WHEN an occurrence row is rendered, THE SYSTEM SHALL show the solar day with its short weekday, the event name as sent by the server, the lunar date with "(nhuận)" for a leap month, the countdown label of BR-CAL-13 computed from the device's date, the major mark when the event is a major event, and the names of the event's groups in the catalogue's group order. (FR-CAL-002, BR-CAL-08, BR-CAL-09, BR-CAL-10, BR-CAL-13)
5. WHEN a year is shown, THE SYSTEM SHALL show only the occurrences of the server response — no Rằm, Mùng Một or any other occurrence added on the device — and no substitute day off. (BR-CAL-05, BR-CAL-11)
6. WHEN the user taps any row, a Rằm or Mùng Một row included, THE SYSTEM SHALL open the event detail for that event and that solar date. (FR-CAL-002, FR-CAL-005)

### Filters

7. WHEN the festival calendar is shown, THE SYSTEM SHALL offer the filter chips "Tất cả", "Lễ lớn", then one chip per group of the response's `groups`, in that order and with the group's name, each showing how many occurrences of the loaded years it holds. (FR-CAL-003, BR-CAL-09, BR-CAL-10)

    > ⚠️ Not confirmed: how a chip shows its count — default: the count after the label in parentheses, e.g. "Lễ lớn (10)" — blocks nothing (layout only); confirm on device QA.

8. WHEN the user picks a filter, THE SYSTEM SHALL show only the matching occurrences — "Tất cả": every occurrence; "Lễ lớn": occurrences of major events; a group: occurrences of events in that group — and SHALL hide a month left with no row. (FR-CAL-003, BR-CAL-09, BR-CAL-10)
9. WHEN a further year is appended while a filter is chosen, THE SYSTEM SHALL apply the same filter to it and update every chip's count. (FR-CAL-003)

### Load the following years

10. WHEN the user scrolls near the end of the list and the last loaded year is before 2100, THE SYSTEM SHALL load the next year and append its months below, one load at a time; WHEN 2100 is loaded, THE SYSTEM SHALL request no further year. (FR-CAL-004)
11. WHEN the next year cannot be loaded and the device has no copy of it, THE SYSTEM SHALL keep the loaded years on screen and show a retry row at the end of the list; WHEN the user taps it, THE SYSTEM SHALL load that year again. (FR-CAL-004, FR-CAL-008)

### Event detail ("Chi tiết ngày lễ")

12. WHEN the event detail opens for an event and a solar date, THE SYSTEM SHALL take the event and its occurrence on that date from the year holding that date — the year already loaded in this session when there is one (no new request), otherwise loaded as in criteria 19–21. (FR-CAL-005, platform)
13. WHEN the detail is rendered, THE SYSTEM SHALL show the image (the shared default image when the event has none), the group names and the major mark, the name, the lunar date, a solar date card with weekday and the BR-CAL-13 countdown, the description as paragraphs and "Phật tử thường làm gì" as a numbered list, splitting both on line breaks only as BR-CAL-14 says; WHEN a section has no content, THE SYSTEM SHALL hide it; THE SYSTEM SHALL show no "Kinh nên tụng", no "Chùa tổ chức" section and no "Nhắc tôi ngày này" button. (FR-CAL-005, BR-CAL-08, BR-CAL-10, BR-CAL-13, BR-CAL-14)

    > ⚠️ Not confirmed (product): which image is "the shared default image" of BR-CAL-14 (no asset in the product spec or the prototype) — blocks the default-image part of criterion 13 and its `tasks.md` Phase 4 item; until it is supplied the hero shows its plain placeholder background with no text; hand back to ba-writer in innerlamp-be.

14. WHEN the year holds no such event or no occurrence of it on that date, THE SYSTEM SHALL show the not-found state, with no retry, and the user leaves with Back. (FR-CAL-005)
15. WHEN the user taps Back on the detail, THE SYSTEM SHALL return to the screen it came from (festival calendar or Home). (platform)

### Home's events block ("Sự kiện Phật giáo")

16. WHEN Home is shown, THE SYSTEM SHALL show one card per month for the current month and the five after it — loading the next year as well when those months cross December — each card holding the rows and the "+N sự kiện khác" count that BR-CAL-15 selects, a row showing the solar day, weekday, event name and lunar label. (FR-CAL-006, BR-CAL-15, BR-CAL-10, BR-CAL-12)
17. WHEN a month of the block has no Buddhist-group occurrence, THE SYSTEM SHALL still show its card, with the empty-month message. (BR-CAL-15)
18. WHEN the user taps a row of the block, THE SYSTEM SHALL open the event detail for that event and date; WHEN the user taps "Tất cả" or "+N sự kiện khác", THE SYSTEM SHALL open the festival calendar on the current month. (FR-CAL-006)

### Device copy and load failure

19. WHEN a year is loaded from the server, THE SYSTEM SHALL keep it on the device as that year's copy, replacing the previous copy; the copy SHALL survive sign-out and app restarts. (FR-CAL-007)

    > ⚠️ Not confirmed: where and how long the device copy is kept — default: one JSON file per solar year in Application Support (`CalendarEvents/<year>.json`, not in Caches so the system does not purge it), not tied to an account, copies of years before the current one deleted when a year loads — blocks nothing; recorded so it can be changed in review.

20. WHEN the festival calendar, a detail or the home block needs a year that has a device copy, THE SYSTEM SHALL show the copy at once and refresh it from the server; WHEN that refresh fails — no connection, timeout, 429, 5xx or an unreadable response — THE SYSTEM SHALL keep the copy on screen with a note that the data may be out of date. (FR-CAL-007, NFR-CAL-03)

    > ⚠️ Not confirmed: show the copy first and refresh, or wait for the server and fall back to the copy — default: copy first, then refresh in place (it meets the 0.5 s of NFR-CAL-03); the out-of-date note appears only when the refresh fails — blocks nothing.

21. WHEN a year cannot be loaded and the device has no copy of it, THE SYSTEM SHALL show the failure with a retry — a distinct title when the device is offline — on the festival calendar as a full-screen state, on the detail as its error state, and on Home in place of the block's cards (the block does not disappear); WHEN the retry succeeds, THE SYSTEM SHALL show the content. (FR-CAL-008)

    > ⚠️ Not confirmed: the home block when only one of its two years fails and has no copy — default: the cards of the year that loaded show their rows, the cards of the failed year show the failure message with retry — blocks nothing.

22. WHEN the server answers 429 (too many requests from this IP), THE SYSTEM SHALL treat it as a failed load (criteria 20–21) and SHALL NOT retry on its own. (FR-CAL-008, platform)

    > ⚠️ Not confirmed: 429 handling — default: the same path as a server error, the user retries; no automatic retry or back-off — blocks nothing.

### Rules correctness and responsiveness

23. WHEN the unit tests run, THE SYSTEM SHALL pass every case of the product vector files `rules/countdown.json`, `rules/ordering.json` and `rules/home-block.json` against the iOS functions that compute the countdown, the order and the home block; `rules/event-placement.json` is run by the backend only. (BR-CAL-13, BR-CAL-12, BR-CAL-15, product §4.1)
24. WHEN the festival calendar opens on a 4G connection, THE SYSTEM SHALL show the current year within 2 s, and within 0.5 s from the device copy when one exists; grouping, filtering and counting run off the main thread. (NFR-CAL-03, platform)

## Error → UI mapping

Operation: `GET /v1/calendar/events?year=` (innerlamp-be `openapi.yaml`, operation `calendarEvents`). The
schema and error codes stay there. Copy: see the ⚠️ under "Pending".

| Failure case | Device copy of that year | What the user sees |
|---|---|---|
| offline / timeout | yes | the copy + out-of-date note (criterion 20) |
| offline / timeout | no | festival calendar: full-screen offline state + "Thử lại"; detail: offline error state + retry; Home: offline message + retry in place of the block's cards; next year: retry row at the end of the list (criteria 11, 21) |
| 5xx, 429, unreadable response | yes | the copy + out-of-date note |
| 5xx, 429, unreadable response | no | same as offline with no copy, with the "could not load" title instead of the offline title |
| 400 `INVALID_YEAR` | — | not reachable: the app asks only 1900…2100 (current year onward, criterion 10); handled as "could not load" |
| 401 (until the route is public) | yes / no | as 5xx; a guest cannot load the calendar until backend Phase 18 ships (Pending, criterion 1) |
| event / occurrence missing in the year (not an HTTP error) | — | detail not-found state, no retry (criterion 14) |

## Out of scope (this feature boundary, not tracked here)

- The lunar calendar screen, the lunar day detail and the daily Buddha picture — they share the product
  slug but come as product v1.x (product §1.2); today they are `Docs/Specs/LunarCalendar/` and
  `Docs/Specs/LunarDayDetail/` and are not changed by this spec.
- Temple events of the user's sangha (courses, registration) — the sangha feature, not this one
  (product §1.2, Appendix A).
- Reminders for an event ("Nhắc tôi ngày này") — later, through ADR-0001's notification list and push.
- "Kinh nên tụng" and "Chùa tổ chức" on the detail (no data source; product §1.2).
- Previous / next event from the detail (FR-CAL-009, website only).
- Back-office editing, substitute days off, personal events, languages other than Vietnamese.
- Computing event dates on the device (BR-CAL-01…07, backend).

## Pending (not yet implemented — see `tasks.md`)

Criteria the shipped code does **not** meet yet (drift against product spec v1.1):

- Criterion 1 — the endpoint keeps `requiresAuth = true`: a guest gets 401 and an empty calendar / block; waits on backend Phase 18 (product matrix FR-CAL-001 iOS `drift`).
- Criteria 3, 10 — the current year comes from the device time zone, and loading goes on to 2200 (`ILFestivalsViewModel.maxYear`) instead of 2100 (FR-CAL-002, FR-CAL-004).
- Criteria 4, 7–9 — rows show no group names and no major mark; the chips are "Tất cả" / "Lễ lớn" / "Rằm & Mùng Một", where "Lễ lớn" means every named event (BR-CAL-10 drift) and there is no chip per group and no count (FR-CAL-003). The major mark needs `is_major` (backend v3.0).
- Criterion 5 — on days with no server occurrence the app adds Rằm / Mùng Một computed with `ILLunarCalendar` (BR-CAL-05 drift, superseded `AS-Festivals-002`).
- Criterion 6 — Rằm / Mùng Một rows (the locally added ones) cannot be tapped.
- Criterion 11 — a failed next year is retried silently on the next scroll, with no retry row.
- Criterion 13 — every section shows a "Chưa có …" text when empty (no image, no group, no description, no guidance), and "Kinh nên tụng" / "Chùa tổ chức" are always shown with their placeholder (BR-CAL-14, FR-CAL-005 drift); no major mark; the default image is ⚠️ product.
- Criterion 14 — the not-found state offers "Thử lại".
- Criteria 16–17 — the block shows the months of the current calendar year only (January to December, not six months from now across the year end), every group, the first three occurrences of a month by date with no tiering, and drops months without occurrences (BR-CAL-15 drift, superseded `AS-Home-003`). Tiering needs `is_major` and `recurrence` (backend v3.0).
- Criteria 19–20 — no device copy at all: the calendar, the detail and the block need the network (`TD-Home-003`, FR-CAL-007).
- Criterion 21 — the festival calendar shows a transient error toast with no retry when the first load fails; the block disappears on any failure (FR-CAL-008).
- Criterion 23 — no product vectors run; the countdown is computed in three places (Festivals, FestivalDetail ViewModels) with the list's copy "còn N ngày" in lower case.
- Criterion 24 — the year is grouped on the main actor (365-day loop in `ILFestivalsUseCaseImpl`); not measured.
- The festival calendar's intro still says every event lists the temples holding it (out of scope, product §1.2).
- Copy — ⚠️ below.

> ⚠️ Not confirmed (product): the copy of the out-of-date note, the load-failure titles and messages (offline / could not load), the retry row, the home block's empty-month message and the not-found message — product v1.1 has no copy list — blocks `tasks.md` Phase 8; until then the existing `catalog.error.*` and `festivalDetail.error.*` strings are kept; hand back to ba-writer in innerlamp-be.

> ⚠️ Not confirmed: keep the code names `Festivals` / `FestivalDetail` for the scenes while the spec folder is `Calendar` (product §1.5) — default: keep them, no rename — blocks nothing.

## Open questions (resolved)

- ~~Which year does the screen open on, how far can it load, what if the next year fails (`AS-Festivals-001`)?~~ → current year (Vietnam time) onward, one year at a time, up to 2100, retry at the end of the list (FR-CAL-002, FR-CAL-004). Criteria 3, 10, 11. Resolved 2026-10-15 by product spec v1.0.
- ~~Which events does the festival calendar show, and does the app add Rằm / Mùng Một (`AS-Festivals-002`)?~~ → every group, with filters; Rằm and Mùng Một come only from the catalogue (BR-CAL-05, BR-CAL-09, FR-CAL-003). Criteria 5, 7–8. Resolved 2026-10-15 by product spec v1.0.
- ~~Format of `guidance` / `long_description` (`AS-FestivalDetail-001`)?~~ → one paragraph / practice per line, split on line breaks only (BR-CAL-14). Criterion 13. Resolved 2026-10-15 by product spec v1.1.
- ~~The "kind" eyebrow on the detail (`AS-FestivalDetail-002`)?~~ → group names plus the major mark (BR-CAL-10). Criterion 13. Resolved 2026-10-15 by product spec v1.0.
- ~~Sections without data on the detail, "Kinh nên tụng" / "Chùa tổ chức" (`TD-FestivalDetail-001`, FestivalDetail v1.0 decision "show Chưa có…")?~~ → empty sections are hidden; sutra and temple sections are out of scope (BR-CAL-14, FR-CAL-005, product §1.2). Criterion 13. Resolved 2026-10-15 by product spec v1.0.
- ~~"Nhắc tôi ngày này" (`TD-FestivalDetail-002`)?~~ → out of scope for v1.0; later through ADR-0001 (product §1.2). Resolved 2026-10-15.
- ~~Which groups and how many rows on Home's block (`AS-Home-003`)?~~ → Buddhist group only, tiered, at most three, six months (BR-CAL-15). Criteria 16–17. Resolved 2026-10-15 by product spec v1.0.
- ~~Offline cache for the calendar (`TD-Home-003`)?~~ → the last loaded copy with an out-of-date note (FR-CAL-007). Criteria 19–20. Resolved 2026-10-15 by product spec v1.0.
- ~~Does the guest see the calendar?~~ → yes (FR-CAL-001). Criterion 1. Resolved 2026-10-15 by product spec v1.0.
- ~~Is "Lễ lớn" every named event?~~ → no, a mark set per event by the content editor (BR-CAL-10), sent as `is_major` (backend design v3.0). Criteria 4, 8. Resolved 2026-10-15.
- ~~How does the app tell Rằm / Mùng Một for the home block's third tier?~~ → the event's `recurrence` is `lunar_monthly` (backend design v3.0), never its code or name. Criterion 16. Resolved 2026-10-15.

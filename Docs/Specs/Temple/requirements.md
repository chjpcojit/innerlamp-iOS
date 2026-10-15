# Requirements — Temple

Version: 3.2
Last updated: 2026-10-15
Status: in-progress — home block, directory screen shell and temple page are built against the old contract; product spec v1.1 / v1.2 alignment pending: server search + region filter + pages of 12 (instead of loading every page and filtering on the device), follow / offering / report removed, open status in Vietnam time with Rằm & Mùng Một hours (normal hours on that row when the temple has none), later fields shown as "Đang cập nhật", distance with location permission, new detail fields, not-found state, product vectors (`tasks.md` Phase 2–8). Blocked in part on the backend contract (q / region / new fields not yet in `openapi.yaml`).
Feature folders: `InnerLamp/Presentation/Scenes/Temple/` (temple page), `InnerLamp/Presentation/Scenes/Temples/` (directory), home block in `InnerLamp/Presentation/Scenes/Home/`
Product spec: innerlamp-be `docs/product/temple/product.md` @ v1.2
Contract: innerlamp-be `docs/specs/api/openapi.yaml` @ a8a016b (info.version 1.0.0) — `GET /v1/temples` there still has page size 20 and no `q` / `region`; `TempleDetail` has no `holiday_operating_hours`, `sangha_body`, `contacts`, `content_updated_month`. The backend spec `docs/specs/features/temple/` v2.0 (AC 5, 39–50) defines them; the `openapi.yaml` update is pending backend work (`tasks.md` Phase 13 there).
Architecture: none (product §2.7 — no ADR)
Implements: BR-TPL-01, BR-TPL-02, BR-TPL-03, BR-TPL-04, BR-TPL-05, BR-TPL-06, BR-TPL-07, BR-TPL-08, BR-TPL-09, FR-TPL-001, FR-TPL-002, FR-TPL-003, FR-TPL-004, FR-TPL-005 (through `Docs/Specs/Onboarding/`), FR-TPL-006, FR-TPL-007, FR-TPL-008, FR-TPL-009, NFR-TPL-01, NFR-TPL-02
Not on iOS: FR-TPL-010 (Backend only)

> See `changelog.md` in this folder for the version history of this spec.

iOS platform spec (layer 2) of the temple directory ("Chùa Việt Nam"). Since v3.0 this one folder
covers both the directory list (formerly `Docs/Specs/Temples/`) and the temple page, as product §1.5
asks. Product behavior — order, featured list, page size, regions, search matching, missing values,
distance, hidden actions, open status — lives in the product spec and is **not** restated here; this
file only says how the iOS app implements those `BR-TPL-*` / `FR-TPL-*`. Written retroactively from the
built screens (v1.0–v2.5.2 of this folder, `Temples` v1.0) and prospectively for the v1.1 and v1.2 changes.

> Layout source: the design prototype (product §1.5), screens `temple` ("Trang chùa") and `temples`
> ("Tất cả chùa") and the home block "Chùa Việt Nam". Copy source: product §3.1.1 and the criteria of
> §3.2 / §3.3; the prototype's copy where those are silent.

## User Story

As a visitor (signed in or not), I want to browse, search and filter Vietnam's Buddhist temples and
open a temple's page, so that I can find a temple, learn about it and get directions there.

## Constraints from the product spec

- **The server orders, searches, filters and pages** (BR-TPL-01, BR-TPL-03, BR-TPL-05, NFR-TPL-02): the
  app shows items in the order received and never sorts, filters or searches the directory on the
  device. The order and search vectors are backend-only (product §4.1).
- **The app computes for display** (product §4.1): distance (BR-TPL-07) and open status (BR-TPL-09) are
  computed on the device and must pass `rules/temple-distance.json` and `rules/temple-open-status.json`.
- **Apps load the next page at the end of the list** (§3.6 row FR-TPL-002).
- **iOS offers Apple Maps and Google Maps** (§3.6 row FR-TPL-008).
- **The short temple list** (FR-TPL-005) is used only by the ordination-temple picker, specified in
  `Docs/Specs/Onboarding/` (BR-ONB-10); this feature does not change it (§3.6 row FR-TPL-005).
- **Offline** (§3.6 row §2.4): the app may keep the last loaded featured list, directory pages and temple
  pages readable offline.
- **User location never leaves the device** (product §3.5, §3.7).

## Acceptance Criteria (EARS notation)

### Home block "Chùa Việt Nam"

1. WHEN Home loads, THE SYSTEM SHALL request `GET /v1/temples/top` and show the returned temples as cards in the order received, without signing in. (FR-TPL-001, BR-TPL-01, BR-TPL-02)
2. WHEN `top` returns no temple, or fails (server error or no connection) and no cached copy exists, THE SYSTEM SHALL show the same block empty state in both cases — no error text, no "Thử lại", no sample temples — and SHALL NOT fail the rest of the Home screen. (FR-TPL-001, BR-TPL-02)
3. WHEN the user taps "Xem tất cả" in the block header, THE SYSTEM SHALL open the directory screen; WHEN the user taps a card, THE SYSTEM SHALL open that temple's page. (FR-TPL-001, FR-TPL-006)

### Directory screen ("Chùa Việt Nam")

4. WHEN the directory screen opens, THE SYSTEM SHALL request page 1 of `GET /v1/temples` with no `q` and no `region`, show its temples in the order received, and show the number of temples found (`total` of that response) in the header subtitle. (FR-TPL-002, BR-TPL-01, BR-TPL-03)
5. WHEN the user scrolls near the end of the loaded rows and the last response says more pages exist, THE SYSTEM SHALL request the next page with the same `q` / `region` and append only its new rows (rows already shown, by `id`, are skipped); THE SYSTEM SHALL never have two requests for the same list in flight and SHALL request nothing more after the last page or an empty page. (FR-TPL-002, BR-TPL-03, NFR-TPL-02, platform)
6. WHEN the user types in the search field, THE SYSTEM SHALL wait for a pause in typing (see `design.md`), then request page 1 with the trimmed term as `q`, and replace the rows and the count with the response. (FR-TPL-003, BR-TPL-05, NFR-TPL-01)
7. WHEN the trimmed term is empty, THE SYSTEM SHALL send no `q` and show the whole directory again from page 1; WHEN the trimmed term is longer than 100 characters, THE SYSTEM SHALL send its first 100 characters. (FR-TPL-003, BR-TPL-05)
8. WHEN the user selects a region chip ("Tất cả · Miền Bắc · Miền Trung · Miền Nam", one at a time), THE SYSTEM SHALL request page 1 with `region` = `north` / `central` / `south` together with the current `q`, or with no `region` for "Tất cả". (FR-TPL-004, BR-TPL-04)
9. WHEN a new search or region request starts, THE SYSTEM SHALL cancel the request in flight for the previous one and SHALL never show a response that belongs to an older search or region. (FR-TPL-003, FR-TPL-004, platform)
10. WHEN a search and/or region request returns no temple, THE SYSTEM SHALL show "Không tìm thấy chùa" with the hint to change the keyword or region. (FR-TPL-003)
11. WHEN the search field is shown, THE SYSTEM SHALL use a placeholder that does not promise a province search (the shipped "Tìm theo tên chùa, tỉnh thành" is wrong under BR-TPL-05). (BR-TPL-05)
    > ⚠️ Not confirmed (product): the placeholder wording of the directory search field — blocks criterion 11's copy; hand back to ba-writer in innerlamp-be.
12. WHEN page 1 fails to load, THE SYSTEM SHALL show the error state with "Thử lại", with the offline title when the device is offline; WHEN a later page fails, THE SYSTEM SHALL keep the rows already shown and offer "Thử lại" at the end of the list. (FR-TPL-002, platform)
13. WHEN the user taps a temple card, THE SYSTEM SHALL open that temple's page; WHEN the user taps back, THE SYSTEM SHALL close the directory. (FR-TPL-006, platform)
14. WHEN a temple card is shown (home block or directory), THE SYSTEM SHALL show the temple's image (placeholder when none), name, type, province, heritage rank and sect, labelled with the shared catalog labels. (§3.1.1, BR-TPL-06)

### Temple page ("Trang chùa")

15. WHEN the temple page opens for an id, THE SYSTEM SHALL request `GET /v1/temples/{id}` without signing in and show the loading state until it answers. (FR-TPL-006)
16. WHEN the response is `404 TEMPLE_NOT_FOUND`, THE SYSTEM SHALL show a "temple not found" state with a way back and no "Thử lại"; WHEN loading fails otherwise, THE SYSTEM SHALL show the error state (offline variant when offline) with "Thử lại". (FR-TPL-006)
17. WHEN the page is shown, THE SYSTEM SHALL show its sections in the prototype's order as listed in FR-TPL-007: image header (heritage-rank chip, sect chip, name, "Còn gọi: …", place as ward and province), status card (open status, distance, both hour rows), facts grid (founding year, heritage rank, sect, region), introduction, organisation (abbot, founder, Buddhist sangha body), architecture & heritage, amenities, visiting notes, events, location & contacts, footer. (FR-TPL-007)
18. WHEN a value of a section is missing, THE SYSTEM SHALL keep the row and show it as BR-TPL-06 says ("Đang cập nhật" for text, "Không có" for amenities except "Kinh sách" (criterion 20), the events empty state, an image placeholder), and SHALL hide the "Còn gọi" line when there is no alias. (BR-TPL-06, FR-TPL-007)
19. WHEN the temple page is shown, THE SYSTEM SHALL keep the architecture style, materials and highlights rows and the photo set visible and show them as "Đang cập nhật" — never hidden — since the contract does not carry them yet. (BR-TPL-06, FR-TPL-007)
20. WHEN the amenities grid is shown, THE SYSTEM SHALL show car parking, motorbike parking, vegetarian meals and retreats from the response, and SHALL show the "Kinh sách" tile with "Đang cập nhật" while the contract has no value for it — never hidden and never "Không có". (FR-TPL-007, BR-TPL-06)
21. WHEN the introduction is taller than the collapsed height, THE SYSTEM SHALL collapse it with "Đọc thêm" and toggle "Đọc thêm" / "Thu gọn" on tap; WHEN it fits, THE SYSTEM SHALL show no toggle. (FR-TPL-007)
22. WHEN visiting notes exist, THE SYSTEM SHALL number them "01", "02", … in the order received. (FR-TPL-007)
23. WHEN the footer is shown and the response has an update month, THE SYSTEM SHALL show it; WHEN it has none, THE SYSTEM SHALL show an empty footer (no report link, BR-TPL-08). (FR-TPL-007, BR-TPL-08)
    > ⚠️ Not confirmed (product): the footer wording and month format of the update month (prototype "Cập nhật …"; the contract carries `YYYY-MM`) — blocks the footer copy task in `tasks.md` Phase 4; hand back to ba-writer in innerlamp-be.

### Actions (BR-TPL-08)

24. WHEN the temple page is shown, THE SYSTEM SHALL show only "Chỉ đường" in the action row — no "Theo dõi" / "Đang theo dõi" (hidden, not disabled), no "Cúng dường" — and no "Báo thông tin sai" link anywhere on the page. (BR-TPL-08)

### Open status and hours (BR-TPL-09)

25. WHEN the temple has opening hours, THE SYSTEM SHALL show the open status line computed by BR-TPL-09 from the current instant in Vietnam time (UTC+7), whatever the device's time zone, using the Rằm & Mùng Một hours on lunar days 1 and 15 of the Vietnam date when the temple has them. (BR-TPL-09)
26. WHEN the status card is shown, THE SYSTEM SHALL show the normal-hours row and the Rằm & Mùng Một row, marking the row in force today "Hôm nay" per BR-TPL-09; WHEN the temple has opening hours but no Rằm & Mùng Một hours (the backend sends `""`, backend AC 46), THE SYSTEM SHALL show the normal hours on the Rằm & Mùng Một row, not "Đang cập nhật". (BR-TPL-09)
27. WHEN the temple has no opening hours, THE SYSTEM SHALL hide the status line and show the hours as "Đang cập nhật". (BR-TPL-09, BR-TPL-06)
28. WHEN the page returns to the screen or the app returns to the foreground, THE SYSTEM SHALL recompute the open status from the current instant. (BR-TPL-09, platform)

### Distance (BR-TPL-07)

29. WHEN the user has allowed location access and the device has a location fix, THE SYSTEM SHALL show the distance line computed and formatted by BR-TPL-07 from the user's location to the temple's coordinates; WHEN access is not allowed, not yet decided, or no fix arrives, THE SYSTEM SHALL hide the line. (BR-TPL-07)
30. WHEN the user's location is used, THE SYSTEM SHALL keep it in memory only — never store it and never send it to any server or log. (BR-TPL-07, product §3.5)
31. WHEN the app needs location access, THE SYSTEM SHALL ask for "When In Use" access only. (BR-TPL-07, platform)
    > ⚠️ Not confirmed (product): when the app asks for location access (on the first temple page opened, or only after a user action such as tapping the distance slot) and the wording of the permission purpose text — blocks the location tasks in `tasks.md` Phase 5; hand back to ba-writer in innerlamp-be.

### Directions and contacts (FR-TPL-008)

32. WHEN the user taps "Chỉ đường" or "Google Maps", THE SYSTEM SHALL open Google Maps directions to the temple's coordinates (the Google Maps app when installed, otherwise the Google Maps website); WHEN the user taps "Apple Maps", THE SYSTEM SHALL open Apple Maps directions to the same coordinates. (FR-TPL-008, §3.6 row FR-TPL-008)
33. WHEN the location section is shown, THE SYSTEM SHALL show the full address (`location.full_address`), the region and the coordinates. (FR-TPL-007)
34. WHEN the user taps a contact row that has a value, THE SYSTEM SHALL call the hotline, open the fanpage or website URL as received, or start an email; WHEN the row has no value, THE SYSTEM SHALL show "Đang cập nhật" and do nothing on tap. (FR-TPL-008, BR-TPL-06)

### Events (FR-TPL-009)

35. WHEN the temple page is shown, THE SYSTEM SHALL show the "Sự kiện & khóa học" section with its empty state "Chùa chưa đăng sự kiện nào." — without the prototype's follow hint and without a tap target — until `sangha` provides temple events on iOS. (FR-TPL-009, BR-TPL-08)

### Pickers

36. WHEN another feature lets the user choose a temple, THE SYSTEM SHALL use the short list as specified in `Docs/Specs/Onboarding/` (ordination temple, BR-ONB-10); this feature adds nothing to it. (FR-TPL-005)

### Offline copy (platform)

37. WHEN `top`, the first unfiltered directory page or a temple page cannot be fetched and a copy from an earlier load is on the device, THE SYSTEM SHALL show the copy instead of the error state. (§3.6 row §2.4, platform)
38. WHEN a search or region request cannot be fetched, THE SYSTEM SHALL show the error state with "Thử lại" (searches and filters are not kept offline). (§3.6 row §2.4, NFR-TPL-02, platform)

## Error → UI mapping

Operations are cited, not copied; the contract is innerlamp-be `docs/specs/api/openapi.yaml` (tag Temples).

| Operation | Failure case | What the user sees |
|---|---|---|
| `GET /v1/temples/top` | any failure, no cached copy | the same Home block empty state as an empty `top` — no error text, no "Thử lại"; Home still loads (criterion 2) |
| `GET /v1/temples/top` | any failure, cached copy | the cached cards (criterion 37) |
| `GET /v1/temples` page 1 | offline / unreachable, no copy (or a search / region request) | full error state, offline title, "Thử lại" (criteria 12, 38) |
| `GET /v1/temples` page 1 | `500`, other failure | full error state, generic title, "Thử lại" |
| `GET /v1/temples` page > 1 | any failure | rows kept, "Thử lại" at the end of the list (criterion 12) |
| `GET /v1/temples` | `400 INVALID_FILTER` (`q` / `region`), `400 INVALID_PAGE` | generic error state with "Thử lại" (the app never sends such values — a bug, logged, not a user error) |
| `GET /v1/temples/{id}` | `404 TEMPLE_NOT_FOUND` | "not found" state with a way back; the cached copy of that temple is dropped (criterion 16) |
| `GET /v1/temples/{id}` | offline / unreachable, no copy | error state, offline variant, "Thử lại" |
| `GET /v1/temples/{id}` | offline / unreachable, cached copy | the cached page (criterion 37) |
| `GET /v1/temples/{id}` | `500`, other failure | error state, generic variant, "Thử lại" |

## Out of scope (this feature boundary, not backend work)

- Following a temple — a later feature (product §1.2); the follow button, its stub and its copy are removed.
- Reporting wrong information — dropped (product §1.2).
- Offering — `Docs/Specs/Offering/` (product §1.2, BR-TPL-08); the "Cúng dường" button is removed here.
- Proposing a new temple (`temple-suggestion`): the "Đề xuất" nav-bar action of the prototype
  (TD-Temples-001) and the proposal forms in `Docs/Specs/TempleFinder/` and `Docs/Specs/AddTemple/`.
- The user's own temple, temple events and announcements (`sangha`, `Docs/Specs/Sangha/`); the
  practice-temple picker "Chọn chùa tu tập" (`Docs/Specs/TempleFinder/`), which still loads every
  directory page itself (TD-TempleFinder-002) — not changed by this spec.
- A map of temples, "near me", sorting by distance, ratings and reviews (product §1.2).
- A real interactive map in the location section — it stays a static placeholder.

## Pending (not yet implemented — see `tasks.md`)

- Contract adoption: `q` / `region`, page size 12, the new detail fields and `location.ward` /
  `province` / `full_address` in the DTOs (`tasks.md` Phase 2).

  > ⚠️ Not confirmed: when the backend ships `q` / `region` on `GET /v1/temples` and the four new detail fields, and updates `openapi.yaml` (backend spec v2.0, `tasks.md` Phase 11–13 there) — blocks `tasks.md` Phase 2–3 and the new-field tasks of Phase 4. Until then the server ignores `q` / `region` (unknown query parameters), so the iOS change must not ship before the backend.

- Directory: server search, region filter and continuous paging instead of loading every page and
  filtering on the device; count of temples found (`tasks.md` Phase 3).
- Temple page: hidden actions, open status in Vietnam time with Rằm & Mùng Một hours, new fields,
  not-found state, events empty copy, image placeholder (`tasks.md` Phase 4).
- Distance with location permission (`tasks.md` Phase 5) — blocked on the location ⚠️ (criterion 31).
- Cards per §3.1.1 (`tasks.md` Phase 6).
- Product vectors and tests (`tasks.md` Phase 7).
- Content credits and image rights: product Appendix A item 1 is still open (`⚠️ Not confirmed` in the
  product spec) — blocks public release of the content, not this spec.

## Open questions (resolved during implementation)

- ~~Is the full discovery feature (list + filters + search) part of what shipped?~~ → Superseded: the
  directory list shipped as `Temples` v1.0 (2026-10-11) and is merged into this folder in v3.0, as
  product §1.5 asks. Resolved 2026-10-15.
- ~~Does "Cấp di tích" ever differ between the hero chip and the facts-grid tile?~~ → No, both read
  `heritage_rank`; the two fallback strings of a missing rank are shown as BR-TPL-06 says. Resolved
  2026-09-28.
- ~~Distance from a fixed reference point (Quận 1, TP.HCM)?~~ → No: only with the user's location
  (BR-TPL-07, product v1.0). Resolved 2026-10-15.
- ~~Follow / offering / report actions?~~ → Hidden (BR-TPL-08, product v1.1). Resolved 2026-10-15.
- ~~Device time or Vietnam time for the open status? Rằm & Mùng Một hours?~~ → Vietnam time, with
  Rằm & Mùng Một hours (BR-TPL-09, product v1.1). Resolved 2026-10-15.
- ~~Search on the device (name or address) or on the server?~~ → On the server, name + aliases
  (BR-TPL-05, product v1.0); replaces `Temples` v1.0. Resolved 2026-10-15.
- ~~Four region chips or five ("Tây Nguyên")?~~ → Three regions plus "Tất cả" (BR-TPL-04);
  AS-Temples-001 is confirmed by the product spec. Resolved 2026-10-15.
- ~~While the directory has no "Kinh sách" value, is its tile hidden, "Không có" or "Đang cập nhật"?~~
  → Shown with "Đang cập nhật", never hidden, never "Không có"; the same holds for the architecture
  details and the photo set (BR-TPL-06, FR-TPL-007, product v1.2; criteria 19–20). The shipped app
  already shows the tile as "Đang cập nhật"; the highlights and photo set are not shown today, so
  `tasks.md` Phase 4 gains a task. Resolved 2026-10-15.
- ~~What does the Rằm & Mùng Một row show when the temple has no holiday hours?~~ → The normal hours
  (BR-TPL-09, product v1.2; criterion 26). Unblocks the holiday-row task in `tasks.md` Phase 4 (the
  shipped app shows "Đang cập nhật", which must change). Resolved 2026-10-15.
- ~~What does the Home block show when `top` cannot be loaded?~~ (not a marker here) → The same empty
  state as an empty directory, with no error text, no retry and no sample temples (FR-TPL-001, product
  v1.2; criterion 2). Already the shipped behavior; no design or task change. Resolved 2026-10-15.

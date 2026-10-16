# Requirements — Deity

Version: 1.1.1
Last updated: 2026-10-16
Status: in-progress — home / library carousels, catalogue screen and deity page are built against the old contract; product spec v1.0 alignment pending: "Chư Thiên" (devas) label, server pages of 12 + server type filter (instead of loading every page and filtering on the device), vía (a deity's feast day, kept on a lunar date) from the backend (instead of the on-device lunar scan and "Đản/Vía" (birth anniversary / feast day) name match), related sutras from `GET /v1/deities/{id}/sutras` (instead of the hard-coded title table), iconography shown, "Báo thông tin sai" (Report incorrect information) removed, prototype empty / error state, cache that expires, dead bundled catalogue removed (`tasks.md` Phase 2–8). Vía parts are blocked on the backend contract (not yet in `openapi.yaml`).
Feature folders: `InnerLamp/Presentation/Scenes/Deity/` (deity page), `InnerLamp/Presentation/Scenes/Deities/` (catalogue), the deity carousel of `InnerLamp/Presentation/Scenes/Home/` and `InnerLamp/Presentation/Scenes/Library/`
Product spec: innerlamp-be `docs/product/deity/product.md` @ v1.0
Contract: innerlamp-be `docs/specs/api/openapi.yaml` @ a8a016b (info.version 1.0.0) — tag Deities (`GET /v1/deities/top`, `GET /v1/deities`, `GET /v1/deities/{id}`) and `GET /v1/deities/{id}/sutras` (tag Sutras). There `GET /v1/deities` still has page size 20 and no `next_via` / `via_events` / `date`. Planned shape: innerlamp-be backend deity `docs/specs/features/deity/requirements.md` v3.0 (AC 2, 5, 8, 12, 22, 24–31, 34; designed, contract not yet in `openapi.yaml` — backend `tasks.md` Phase 9).
Architecture: none (product §2.7 — no ADR)
Related product spec: innerlamp-be `docs/product/calendar/product.md` @ v1.2 (BR-CAL-08, BR-CAL-12, BR-CAL-13) — iOS side in `Docs/Specs/Calendar/`
Implements: BR-DTY-01, BR-DTY-02, BR-DTY-03, BR-DTY-04, BR-DTY-05, BR-DTY-06, BR-DTY-07, BR-DTY-08, FR-DTY-001, FR-DTY-002, FR-DTY-003, FR-DTY-004, FR-DTY-005, FR-DTY-006, FR-DTY-007, FR-DTY-008, FR-DTY-009, FR-DTY-010, NFR-DTY-01, NFR-DTY-02
Not on iOS: FR-DTY-011 (Backend only)

> See `changelog.md` in this folder for the version history of this spec.

iOS platform spec (layer 2) of the Buddhas & Bodhisattvas catalogue. As product §1.5 asks, this one
folder covers both the former `Deity` (deity page) and `Deities` (catalogue) scene docs; the code
folders keep their names. Product behavior — types and labels, order, featured list, page size, missing
values, vía source and next vía, vows collapsed, hidden actions — lives in the product spec and is
**not** restated here; this file only says how the iOS app implements those `BR-DTY-*` / `FR-DTY-*`.
Written retroactively from the built screens (scene READMEs of 2026-09-28…2026-10-06,
`Docs/Assumptions/Deity/AS-Deity-DEVA-label.md`) and prospectively for the product v1.0 changes.

> Layout source: the design prototype (product §1.5), screens `buddhas`, `buddhasEmpty`, `buddha`, the
> home section "Thư viện Phật & Bồ Tát" (Library of Buddhas & Bodhisattvas) and the library block / tile. Copy source: product §3.1.1 and
> the criteria of §3.2 / §3.3; the prototype's copy where those are silent.

## User Story

As a visitor (signed in or not), I want to browse the Buddhas, bodhisattvas and devas and open a deity's
page, so that I can learn about them, know their next vía day and start practising with their mantra.

## Constraints from the product spec

- **The server orders, filters and pages** (BR-DTY-02, BR-DTY-03, FR-DTY-003, NFR-DTY-01): the app shows
  items in the order received and never sorts, filters or loads the whole catalogue on the device. The
  order vectors are backend-only (product §4.1).
- **The server gives the vía days and picks the next vía** (BR-DTY-05, BR-DTY-06; backend deity
  requirements v3.0 AC 24, 28, 29): the app never converts a lunar date and never chooses the next vía.
  The app computes only the countdown (BR-CAL-13) from the device date, through the Calendar feature's
  shared rule (`Docs/Specs/Calendar/design.md`, `ILCalendarRules.countdown`).
- **Apps load the next page at the end of the list** (§3.6 row FR-DTY-002).
- **Featured cards** (§3.6 row FR-DTY-001): the iOS carousels show every featured deity received (up to 10).
- **Offline** (§3.6 row §2.4): the app may keep the last loaded featured list, catalogue pages and deity
  pages readable offline.

## Acceptance Criteria (EARS notation)

### Home and library blocks

1. WHEN Home or Library loads, THE SYSTEM SHALL request `GET /v1/deities/top` with the device date as `date` and show every returned deity as a card in the order received, without signing in. (FR-DTY-001, BR-DTY-02, platform)
2. WHEN the user taps "Xem tất cả" (See all) on the Home block "Thư viện Phật & Bồ Tát", the Library block "Chư Phật & Bồ Tát" (Buddhas & Bodhisattvas) or the Library tile "Phật & Bồ Tát" (Buddhas & Bodhisattvas), THE SYSTEM SHALL open the catalogue; WHEN the user taps a card, THE SYSTEM SHALL open that deity's page. (FR-DTY-001, FR-DTY-004)
3. WHEN `top` returns no deity, or fails and no cached copy exists, THE SYSTEM SHALL show the block's empty state and no deity card, and SHALL NOT fail the Home or Library screen. (FR-DTY-010, BR-DTY-02)
   > ⚠️ Not confirmed (product): what the Home / Library block empty state shows — copy (today "Đang cập nhật" (Updating) for both "no deity" and "failed") and whether it offers "Thử lại" (Retry) — blocks the block empty-state task in `tasks.md` Phase 6; hand back to ba-writer in innerlamp-be.

### Deity card (blocks and catalogue)

4. WHEN a deity card is shown, THE SYSTEM SHALL show the image (the summary's thumbnail, else its full image, else the placeholder), the type label "Phật" (Buddha) / "Bồ Tát" (Bodhisattva) / "Chư Thiên", the name, the core virtue when present, and "Vía dd/MM âm lịch" (Feast day dd/MM lunar calendar) from the summary's next vía, or no vía line when it has none. (FR-DTY-002, BR-DTY-01, BR-DTY-04, BR-DTY-06)
   > ⚠️ Not confirmed (product): whether the card's "Vía dd/MM âm lịch" marks a leap month ("nhuận" (leap), BR-CAL-08) when the next vía falls in one — blocks the card copy for leap-month vía only; hand back to ba-writer in innerlamp-be.

### Catalogue ("Chư Phật & Bồ Tát")

5. WHEN the catalogue opens, THE SYSTEM SHALL request page 1 of `GET /v1/deities` with no `type` and the device date as `date`, show its deities in the order received, and show "{N} vị · tiểu sử, đại nguyện, thần chú" ({N} figures · biographies, great vows, mantras) with N = `total` of that response. (FR-DTY-002, BR-DTY-02, BR-DTY-03)
6. WHEN the user scrolls near the end of the loaded cards and the last response says more pages exist, THE SYSTEM SHALL request the next page with the same `type` and append only its new cards (cards already shown, by `id`, are skipped); THE SYSTEM SHALL never have two requests for the same list in flight and SHALL request nothing more after the last page or an empty page. (FR-DTY-002, BR-DTY-03, NFR-DTY-01, platform)
7. WHEN the user selects a chip ("Tất cả · Chư Phật · Bồ Tát" (All · Buddhas · Bodhisattvas), one at a time), THE SYSTEM SHALL request page 1 with `type` = `BUDDHA` / `BODHISATTVA`, or with no `type` for "Tất cả" (All), replace the cards with the response and set N to its `total`; there is no "Chư Thiên" chip. (FR-DTY-003, BR-DTY-01, NFR-DTY-02)
8. WHEN a new chip is selected while a request is in flight, THE SYSTEM SHALL cancel the previous request and SHALL never show a response that belongs to an earlier chip; tapping the selected chip again changes nothing. (FR-DTY-003, platform)
9. WHEN page 1 cannot be loaded and no cached copy exists, or the catalogue holds no deity, THE SYSTEM SHALL show the empty state "Chưa có thông tin chư Phật" (No information on the Buddhas yet) with the hint "Chưa tải được tiểu sử và đại nguyện của chư Phật, Bồ Tát. Kiểm tra kết nối rồi thử lại." (Could not load the biographies and great vows of the Buddhas and Bodhisattvas. Check your connection and try again.), a "Thử lại" action that requests page 1 of the current chip again, and a "Xem lịch lễ vía" (See the feast-day calendar) action that opens the festival calendar. (FR-DTY-010)
   > ⚠️ Not confirmed (product): what the catalogue shows when a type chip returns no deity while "Tất cả" has some (FR-DTY-010 covers only "cannot be loaded or holds no deity") — the same empty state, or a filter-specific message — blocks the filtered-empty copy in `tasks.md` Phase 3; hand back to ba-writer in innerlamp-be.
10. WHEN a later page fails, THE SYSTEM SHALL keep the cards already shown and offer "Thử lại" at the end of the list. (FR-DTY-002, platform)
11. WHEN the user taps a card, THE SYSTEM SHALL open that deity's page; WHEN the user taps back, THE SYSTEM SHALL close the catalogue. (FR-DTY-004, platform)

### Deity page ("Chi tiết Phật / Bồ Tát" (Buddha / Bodhisattva details))

12. WHEN the deity page opens for an id, THE SYSTEM SHALL request `GET /v1/deities/{id}` with the device date as `date`, without signing in, and show the loading state until it answers. (FR-DTY-004)
13. WHEN the response is `404 DEITY_NOT_FOUND`, THE SYSTEM SHALL show a "deity not found" state with a way back and no "Thử lại"; WHEN loading fails otherwise and no cached copy exists, THE SYSTEM SHALL show the error state (offline variant when offline) with "Thử lại". (FR-DTY-004)
14. WHEN the page is shown, THE SYSTEM SHALL show its parts in the order of FR-DTY-005: image with type label and pure land; name, honorific title, Sanskrit name and Chinese name (as text, not only as the watermark); the next-vía card; core virtue and canonical source line; "Tiểu sử" (Biography); "Đại nguyện" (Great vows); "Hình tượng" (Iconography); "Thần chú & danh hiệu" (Mantras & honorific titles) with its cards and the two actions; "Kinh liên quan" (Related sutras); the footer. (FR-DTY-005)
15. WHEN a field, section or mantra card has no content, THE SYSTEM SHALL leave it out as BR-DTY-04 says, and SHALL show the placeholder image when the deity has no image. (BR-DTY-04)
16. WHEN the biography is taller than the collapsed height, THE SYSTEM SHALL collapse it with "Đọc thêm" (Read more) and toggle "Đọc thêm" / "Thu gọn" (Show less) on tap; WHEN it fits, THE SYSTEM SHALL show no toggle. (FR-DTY-005)
17. WHEN the vows are shown, THE SYSTEM SHALL number them from 1 in the order received and collapse / expand them as BR-DTY-07 says ("Xem đủ N đại nguyện" (See all N great vows) / "Thu gọn"). (BR-DTY-07)
18. WHEN the deity has iconography, THE SYSTEM SHALL show the "Hình tượng" section with posture, seat or mount, sacred objects and symbolic meaning, each row only when it has content. (FR-DTY-005, BR-DTY-04)
    > ⚠️ Not confirmed (product): the row labels of "Hình tượng" (posture, seat or mount, sacred objects, symbolic meaning) — the prototype has no such section and product §3.1.1 gives no copy — blocks the iconography copy task in `tasks.md` Phase 4; hand back to ba-writer in innerlamp-be.
19. WHEN the mantra section is shown, THE SYSTEM SHALL show up to three cards — "Danh hiệu" (honorific title), "Thần chú" (short mantra, Sino-Vietnamese then Sanskrit), "Đà-la-ni" (dhāraṇī name and excerpt) — followed by one "Trì niệm với tràng hạt" (Recite with the mala) action and one "Chia sẻ" (Share) action for the page (not one pair per card). (FR-DTY-005, FR-DTY-008, FR-DTY-009, BR-DTY-04)
20. WHEN the footer is shown, THE SYSTEM SHALL show only "Nội dung do Ban biên tập tổng hợp từ kinh điển" (Content compiled by the Editorial Board from the scriptures) — no "Báo thông tin sai", no favourite, no follow. (BR-DTY-08)

### Next vía (FR-DTY-006)

21. WHEN the deity page response has a next vía, THE SYSTEM SHALL show the vía card with that vía's name, lunar day and month (months 1 and 12 as "THÁNG GIÊNG" (FIRST MONTH) / "THÁNG CHẠP" (TWELFTH MONTH), "nhuận" after the month for a leap month), its solar date with weekday and its countdown "Hôm nay" (Today) / "Ngày mai" (Tomorrow) / "Còn n ngày" (n days left) computed from the device date (BR-CAL-13); WHEN it has none, THE SYSTEM SHALL show no vía card. (FR-DTY-006, BR-DTY-06, BR-DTY-04, BR-CAL-08, BR-CAL-13)
22. WHEN the vía card is shown, THE SYSTEM SHALL list all the deity's vía days in the order received, each with its name and next occurrence (lunar and solar date). (FR-DTY-006, BR-DTY-05)
    > ⚠️ Not confirmed (product): how a listed vía day without an occurrence in the window the server gives (backend AC 28: `next_occurrence: null`, listed last) is shown — name only, or left out — blocks the vía-list row task in `tasks.md` Phase 4; hand back to ba-writer in innerlamp-be.
23. WHEN the user taps "Lịch lễ" (Festival calendar) on the vía card, THE SYSTEM SHALL open the festival calendar. (FR-DTY-006)
24. WHEN the page comes back on screen on a later device date than the one it was loaded with, THE SYSTEM SHALL load it again, so the next vía and countdown follow today. (BR-DTY-06, BR-CAL-13, platform)

### Related sutras (FR-DTY-007)

25. WHEN the deity page is shown, THE SYSTEM SHALL request page 1 of `GET /v1/deities/{id}/sutras` (no `role`) and list the returned sutras under "Kinh liên quan" in the order received, each by its Vietnamese title; WHEN it returns no sutra, THE SYSTEM SHALL show no section. (FR-DTY-007, BR-DTY-04)
    > ⚠️ Not confirmed (product): FR-DTY-007 says "in the sutra library's order", but the endpoint orders by the deity's role (SUBJECT, SPEAKER, MENTIONED) then editorial order — same question as backend deity requirements v3.0 — blocks only the order check of `tasks.md` Phase 5 (iOS shows the order received either way); hand back to ba-writer in innerlamp-be.
    > ⚠️ Not confirmed (product): whether "Kinh liên quan" shows every linked sutra (more than one page of 20) or a capped number — blocks paging of the section in `tasks.md` Phase 5 (iOS shows page 1 until answered); hand back to ba-writer in innerlamp-be.
26. WHEN the user taps a related sutra, THE SYSTEM SHALL open that sutra's page by its server id. (FR-DTY-007)
27. WHEN the related-sutras request fails, THE SYSTEM SHALL show the rest of the page and no "Kinh liên quan" section. (FR-DTY-007, platform)
    > ⚠️ Not confirmed (product): whether a failed related-sutras load hides the section (as criterion 27, the shipped-style default) or shows an inline retry — blocks nothing else; hand back to ba-writer in innerlamp-be.

### Practice actions

28. WHEN the deity has a short mantra in Sino-Vietnamese, THE SYSTEM SHALL offer "Trì niệm với tràng hạt", which opens the mala with that text and a count of 0; WHEN it has none, THE SYSTEM SHALL not offer the action. (FR-DTY-008, BR-DTY-04)
29. WHEN the user taps "Chia sẻ", THE SYSTEM SHALL open the system share sheet with the deity's name and short mantra (Sino-Vietnamese, then Sanskrit when present), leaving out missing values. (FR-DTY-009, BR-DTY-04)
    > ⚠️ Not confirmed (product): whether the shared text also carries a link to the deity's web page (product Appendix A item 3) — blocks the final share text in `tasks.md` Phase 4.

### Offline copy and freshness (platform)

30. WHEN `top`, the first unfiltered catalogue page or a deity page cannot be fetched and a copy from an earlier load is on the device, THE SYSTEM SHALL show the copy instead of the empty / error state. (§3.6 row §2.4, platform)
31. WHEN a filtered catalogue page cannot be fetched, THE SYSTEM SHALL show the empty / error state of criterion 9 (filtered pages are not kept offline). (§3.6 row §2.4, NFR-DTY-02, platform)
32. WHEN the server can be reached, THE SYSTEM SHALL show the server's answer, not a stored copy — stored copies are used only when the server cannot be reached. (BR-DTY-06, platform)
    > ⚠️ Not confirmed (product): what a copy shown offline does with a next vía whose solar date is before today (the stored answer is stale; the app does not pick the next vía itself, BR-DTY-06) — hide the vía line / card, or show it with "Đã qua" (Passed) — blocks the stale-vía task in `tasks.md` Phase 2; hand back to ba-writer in innerlamp-be.

## Error → UI mapping

Operations are cited, not copied; the contract is innerlamp-be `docs/specs/api/openapi.yaml` (tag Deities,
`GET /v1/deities/{id}/sutras` under Sutras), plus `INVALID_DATE` from backend deity requirements v3.0 AC 26.

| Operation | Failure case | What the user sees |
|---|---|---|
| `GET /v1/deities/top` | any failure, no cached copy | block empty state; Home / Library still load (criterion 3) |
| `GET /v1/deities/top` | any failure, cached copy | the cached cards (criterion 30) |
| `GET /v1/deities` page 1 | offline / unreachable, no copy (or a filtered request) | empty state "Chưa có thông tin chư Phật" + "Thử lại" + "Xem lịch lễ vía" (criteria 9, 31) |
| `GET /v1/deities` page 1 | unfiltered, cached copy | the cached cards and count (criterion 30) |
| `GET /v1/deities` page 1 | `500`, other failure | same empty state as offline (criterion 9) |
| `GET /v1/deities` page > 1 | any failure | cards kept, "Thử lại" at the end of the list (criterion 10) |
| `GET /v1/deities` | `400 INVALID_PAGE` / `INVALID_DEITY_TYPE` / `INVALID_DATE` | same as `500` (the app never sends such values — a bug, logged, not a user error) |
| `GET /v1/deities/{id}` | `404 DEITY_NOT_FOUND` | "not found" state with a way back; the cached copy of that deity is dropped (criterion 13) |
| `GET /v1/deities/{id}` | offline / unreachable, cached copy | the cached page (criterion 30) |
| `GET /v1/deities/{id}` | offline / unreachable, no copy | error state, offline variant, "Thử lại" |
| `GET /v1/deities/{id}` | `500`, `400 INVALID_DATE`, other failure | error state, generic variant, "Thử lại" |
| `GET /v1/deities/{id}/sutras` | any failure, incl. `404 DEITY_NOT_FOUND` | no "Kinh liên quan" section; the rest of the page stays (criterion 27, ⚠️) |

## Out of scope (this feature boundary, not backend work)

- Search in the catalogue (product §1.2).
- "Báo thông tin sai", favourite, follow, prayer requests, vía reminders (product §1.2, BR-DTY-08).
- A dedicated share layout (the prototype's three-card share screen) — the system share sheet is used.
- The festival calendar and the sutra page themselves — `Docs/Specs/Calendar/`, `Docs/Specs/Sutra/`;
  the mala — `Docs/Specs/Mala/`. This feature only opens them.
- Loading the catalogue content (FR-DTY-011, backend only).

## Pending (not yet implemented — see `tasks.md`)

- Contract adoption: page size 12, `type` on the list, `date` on the three deity routes, `next_via` on
  summaries and detail, `via_events` on the detail; move off the deprecated `lunar_memorial_days`
  (`tasks.md` Phase 2).

  > ⚠️ Not confirmed: when the backend ships deity v3.0 (`next_via`, `via_events`, `date`, page size 12) and updates `openapi.yaml` (backend `tasks.md` Phase 8–10, the contract update is Phase 9) — blocks `tasks.md` Phase 2 and the vía tasks of Phase 3, 4 and 6. Until then the vía line stays as shipped; the paging / filter / sutra work of Phase 3–5 needs only the current contract (page size is read from the response).

- Catalogue: server type filter and continuous paging instead of loading every page and filtering on the
  device; count per filter; prototype empty state (`tasks.md` Phase 3).
- Deity page: label "Chư Thiên", name block, canonical source line, iconography, single action row, vía
  card from the backend with the vía list, not-found state, footer without "Báo thông tin sai"
  (`tasks.md` Phase 4).
- Related sutras from `GET /v1/deities/{id}/sutras` (`tasks.md` Phase 5).
- Home / Library blocks: vía line, block empty state (`tasks.md` Phase 6).
- Removal of the dead bundled catalogue and its repository (`tasks.md` Phase 7).
- Content review and image rights: product Appendix A item 1 is still open — blocks public release of the
  content, not this spec.

## Open questions (resolved during implementation)

- ~~Label of the `DEVA` type and whether it has a filter chip (AS-Deity-DEVA: "Thiên Nữ" (celestial maidens), no chip)?~~ →
  Label "Chư Thiên", no chip, listed under "Tất cả" only (BR-DTY-01, product v1.0). The assumption is
  closed in `tasks.md` Phase 8. Resolved 2026-10-15.
- ~~Load every page and filter on the device, or server paging + `type`?~~ → Server pages of 12 and the
  server `type` filter (BR-DTY-03, FR-DTY-003, NFR-DTY-01). Resolved 2026-10-15.
- ~~Where do vía days and the next vía come from (on-device 400-day lunar scan, "Đản/Vía" name match)?~~ →
  From the festival calendar through the backend, which also picks the next vía; the app only counts
  down (BR-DTY-05, BR-DTY-06; backend deity requirements v3.0). Resolved 2026-10-15.
- ~~Related sutras by matching `canonical_source` titles against a hard-coded table?~~ → From
  `GET /v1/deities/{id}/sutras` (FR-DTY-007, backend AC 34). Resolved 2026-10-15.
- ~~Show iconography? Keep "Báo thông tin sai"?~~ → Show "Hình tượng"; drop the report text (FR-DTY-005,
  BR-DTY-08). Resolved 2026-10-15.
- ~~Fill the list's vía line by fetching every detail?~~ → No: summaries carry `next_via` (backend AC 2,
  24). Resolved 2026-10-15.

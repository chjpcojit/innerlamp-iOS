# Requirements — Sutra

Version: 1.0.1
Last updated: 2026-10-16
Status: in-progress — the sutra list (paging, topic + duration chips, server search) and the sutra page (all fields the API returns) are built against the backend; the reading view and the library tiles still run on a sample catalogue and can open the wrong text; product spec v1.0 alignment pending: 60-minute chip and chip / card copy, Vietnamese-first default version (BR-STR-05), licence labels and the short unreviewed notice, per-version facts, linked deities that open the deity page, real text from `/lines` with table of contents, section jump and version switch, four remembered font sizes shared with the settings (three backgrounds dropped), the simulated player removed, error / empty / not-found states with retry, and the quote of the day by date instead of random on Home (`tasks.md` Phase 2–8).
Feature folders: `InnerLamp/Presentation/Scenes/Sutras/` (list), `InnerLamp/Presentation/Scenes/SutraDetail/` (sutra page), `InnerLamp/Presentation/Scenes/Reader/` (reading view), and the quote code in `InnerLamp/Domain/UseCases/SutraQuote/` used by `InnerLamp/Presentation/Scenes/Home/` and `InnerLamp/Presentation/Scenes/LunarDayDetail/`
Product spec: innerlamp-be `docs/product/sutra/product.md` @ v1.0
Contract: innerlamp-be `docs/specs/api/openapi.yaml` @ a8a016b (info.version 1.0.0) — tag Sutras: `GET /v1/sutras` (`sutrasList`), `GET /v1/sutras/{id}` (`sutrasGet`), `GET /v1/sutras/{id}/lines` (`sutrasLines`); `GET /v1/deities/{id}/sutras` (`deitiesSutras`) is called by the Deity feature (`Docs/Specs/Deity/`). The quote of the day has no contract (product Appendix B item 4); the app keeps its bundled file.
Architecture: none (product §2.7 — no ADR)
Implements: BR-STR-01, BR-STR-02, BR-STR-03, BR-STR-04, BR-STR-05, BR-STR-06, BR-STR-07, BR-STR-08, BR-STR-09, BR-STR-10, BR-STR-11, BR-STR-12, BR-STR-13, FR-STR-001, FR-STR-002, FR-STR-003, FR-STR-004, FR-STR-005, FR-STR-006, FR-STR-007, FR-STR-008, FR-STR-009, FR-STR-010, FR-STR-011, NFR-STR-01, NFR-STR-02
Not on iOS: FR-STR-012 (Backend only), NFR-STR-03 (Backend only)

> See `changelog.md` in this folder for the version history of this spec.

iOS platform spec (layer 2) of the sutra library ("Kinh sách" — sutras, verses and mantras). As product
§1.5 asks, this one folder merges the former `Docs/Specs/Sutras/` v1.2 (list), `Docs/Specs/SutraDetail/`
v1.4 (sutra page) and `Docs/Specs/Reader/` v1.1 (reading view), and absorbs their assumptions
(`AS-Sutras-001…003`, `AS-SutraDetail-001…002`, `AS-Reader-001…003`) and tech debt (`TD-Sutras-001…003`,
`TD-SutraDetail-001…003`, `TD-Reader-001…003`). It also covers the daily quote (`ILSutraQuoteUseCase`).
The code folders keep their names (`Sutras`, `SutraDetail`, `Reader`). The old spec folders and entries
were deleted on 2026-10-16 (`changelog.md` v1.0.1). `Docs/Specs/Library/`,
`Docs/Specs/Downloads/` and `Docs/Specs/Player/` are separate later specs and are not touched here.
Product behavior — order, filters, search, Vietnamese-first titles and versions, licence and notice,
links to Buddhas, the quote rule, reading preferences, no audio, states — lives in the product spec and
is **not** restated here; this file only says how the iOS app implements those `BR-STR-*` / `FR-STR-*`.
Written retroactively from the built screens and prospectively for the product v1.0 changes.

> Layout source: the design prototype `InnerLamp Prototype.dc.html` (product §1.5), screens `sutras`
> ("Kinh sách"), `isDetail` ("Chi tiết bài kinh" — sutra page) and `isReader` ("Tụng kinh" — reading view).
> Where the prototype and the product spec differ (chant-along player with audio, progress card, download
> button, three reading backgrounds), the product spec wins.

## User Story

As a visitor (signed in or not), I want to find a sutra, verse or mantra on my iPhone by topic, length or
name, read its information, sources and licence, read the whole text in a comfortable size, follow its
links to the Buddhas and bodhisattvas it concerns, and see a verse of the day, so that I can study and
chant from the app with confidence about where the text comes from.

## Constraints from the product spec

- **The server orders, filters, searches and pages** (BR-STR-02, BR-STR-03, BR-STR-04): the app shows
  texts in the order received and never sorts, filters or matches locally. The app only builds the
  request (chip → query parameter; the term trimmed and cut to 100 characters) and drops responses of
  a superseded request. The vectors `rules/sutra-browse.json` and `rules/sutra-search-match.json` are
  backend-only for iOS (product §4.1: the clients that filter or search on the device run them; iOS does
  neither).
- **Page size**: apps load the next page at the end of the list (§3.6 row FR-STR-001); the page size is
  read from the response, never assumed (20 today, product Appendix A item 12).
- **Vietnamese first** (BR-STR-05): whatever the app language, the feature shows `titles.vi` and opens the
  Vietnamese version chosen by the product rule. iOS ships `vi.json` only, so no copy is translated here.
- **The text is shown as stored** (BR-STR-06): no gloss, cue, opening ritual or spelling change is added
  by the app.
- **No audio** (BR-STR-12): the app has no player, progress, pace, seek or highlight-by-timer. What the
  reading view offers instead is an open product question (Appendix A item 4).
- **Public** (BR-STR-13): no call of this feature sends `Authorization`.
- **The quote needs no network** (BR-STR-10, §3.7): it comes from the bundled quote file.
- **Offline** (§2.4 / §3.6 row §2.4): the apps *may* keep the last loaded pages readable offline. This
  release is network-only (see `design.md` "Caching"); nothing is cached beyond `ILRemoteImageView`.
- **Every text is unreviewed today** (product §2.5): labels, links, Vietnamese titles and the Great
  Compassion Mantra were not checked by someone knowledgeable; the page says so (BR-STR-07).

## Acceptance Criteria (EARS notation)

### The sutra list ("Kinh sách")

1. WHEN the list opens (from the Library tile "Kinh sách" or the group link "Xem tất cả" (See all)), THE SYSTEM SHALL show the header, the search field, the topic and duration chip rows and a skeleton, request `GET /v1/sutras?page=1` without signing in, then show the texts in the order received and the count "{N} bản kinh" ({N} texts) with N = `total` of the response. (FR-STR-001, BR-STR-02, BR-STR-13, NFR-STR-02)
2. WHEN a card is shown, THE SYSTEM SHALL show the Vietnamese title (`titles.vi`; only if the server sent none, the English, then the Pāli title), beneath it the original title when the server sent a Pāli or English title that differs, the kind label "Kinh" (sutra) / "Kệ" (verse) / "Chú" (mantra) and the tradition label "Nam Tông" (Theravāda) / "Bắc Tông" (Mahāyāna) / "Kim Cang Thừa" (Vajrayāna), "{collection} · {citation code}" with each part only when non-empty, "khoảng N phút" (about N minutes) when the server has an estimate, the short summary when non-empty, and the mark "Hằng ngày" (Daily) when `daily_chant` is true. (FR-STR-001, BR-STR-01, BR-STR-05, BR-STR-08)
   > ⚠️ Not confirmed (product): whether the ten purpose badges ("Cầu an", "Cầu siêu", …) stay on the card — product §3.1.1 lists the card without them (only the daily-chanting mark) and iOS shows them today; they stay as built until answered — blocks the purpose badges of `tasks.md` Phase 3; hand back to ba-writer in innerlamp-be.
3. THE SYSTEM SHALL show on a card no "Có audio" (Has audio) badge, no "✓ Đã tải về" (Downloaded) badge and no translator line. (BR-STR-12, platform)
4. WHEN the user scrolls within 120 pt of the end of the list and the last response says more pages exist, THE SYSTEM SHALL request the next page with the same chips and term, show "Đang tải thêm…" (Loading more…) while it loads and append only texts not shown yet (by `id`); THE SYSTEM SHALL never have two page requests in flight. (FR-STR-001, BR-STR-02, platform)
5. WHEN the last page has been loaded (`page >= total_pages`) or a page comes back empty, THE SYSTEM SHALL request no further page, add no card, show no error and end the list with "Đã hiển thị tất cả bản kinh" (Every text is shown). (FR-STR-001)
6. THE SYSTEM SHALL show the topic chips "Tất cả" (All), "Hằng ngày" (Daily), "Cầu an", "Cầu siêu", "Trì chú", "Sám hối", "Hồi hướng", "Phát nguyện", "Báo hiếu", "Thiền định", "Học giáo lý", "Quy y thọ giới", "Nam Tông", "Bắc Tông", "Kim Cang Thừa" in this order, one selected at a time; WHEN the user selects one, THE SYSTEM SHALL request page 1 with `daily=true`, `purpose=<code>` or `tradition=<code>` (none for "Tất cả"). (FR-STR-002, BR-STR-03)
7. THE SYSTEM SHALL show the duration chips "Tất cả", "Tối đa 5 phút" (At most 5 minutes), "Tối đa 15 phút", "Tối đa 30 phút", "Tối đa 60 phút" in this order, one selected at a time; WHEN the user selects one, THE SYSTEM SHALL request page 1 with `max_minutes` = 5 / 15 / 30 / 60 (none for "Tất cả"). (FR-STR-002, BR-STR-03, BR-STR-08)
8. WHEN a chip changes, THE SYSTEM SHALL select it at once and restart from page 1 keeping the other chip row and the typed search term, so that both chips and the term apply together, and show the new count; selecting the selected chip again SHALL change nothing; a response that belongs to an older chip or term SHALL be dropped. (FR-STR-002, FR-STR-003, BR-STR-03, BR-STR-04; stale-response drop: platform)
9. WHEN the user pauses typing in the search field (300 ms), THE SYSTEM SHALL restart from page 1 with `q=<term>`, the term trimmed and cut to 100 characters, and send no `q` for a blank term; WHEN the search field has text, THE SYSTEM SHALL show a round "×" that empties it and, after the same pause, shows the list again. (FR-STR-003, BR-STR-04; debounce and "×": platform)
10. WHILE a term is active, THE SYSTEM SHALL show the texts in the order received and the count of matches "{N} bản kinh", and SHALL NOT match, reorder or hide any text on the device. (FR-STR-003, BR-STR-02, BR-STR-04)
11. WHILE page 1 loads (first open, a chip change or a new term), THE SYSTEM SHALL show the skeleton and no empty state; WHEN page 1 cannot be loaded, THE SYSTEM SHALL show an error state (the offline variant when there is no connection) with "Thử lại" (Try again) in place of the list, no sample text, and WHEN the user taps "Thử lại", request page 1 again with the current chips and term. (FR-STR-011)
12. WHEN a response holds no text, THE SYSTEM SHALL show an empty state that says which case it is: the library is empty (no chip, no term), no text matches the chips, or no text matches the search — and none of them reads like a connection failure. (FR-STR-011, BR-STR-03, BR-STR-04)
    > ⚠️ Not confirmed (product): the copy of the error, empty, search-empty and not-found states (product Appendix A item 10) — blocks the state copy of `tasks.md` Phase 3; until then the existing `sutras.empty.*` and `catalog.error.*` strings are kept.
    > ⚠️ Not confirmed (product): whether the search-empty state offers "Gửi yêu cầu bản kinh" (Request a text) as the prototype does, and what it does (Appendix A item 9) — blocks only that action of the search-empty state.
13. WHEN a later page fails, THE SYSTEM SHALL keep the texts already shown, remove the loading line and show "Thử lại" at the end of the list, which requests that page again. (FR-STR-011, platform)
14. WHEN the user taps a card, THE SYSTEM SHALL open that text's sutra page by its server `id`; WHEN the user taps back, THE SYSTEM SHALL close the list. (FR-STR-004, platform)

### The sutra page ("Chi tiết bài kinh")

15. WHEN the sutra page opens for an id, THE SYSTEM SHALL show the loading state and request `GET /v1/sutras/{id}` without signing in. (FR-STR-004, BR-STR-13)
16. WHEN the page is shown, THE SYSTEM SHALL show at the top the kind and tradition labels, the Vietnamese title with the original title (`original_title`, else the Pāli or English title that differs) beneath, "khoảng N phút" when the server has an estimate, and "{collection} · {citation code}" with each part only when non-empty. (FR-STR-004, BR-STR-01, BR-STR-05, BR-STR-08)
17. WHEN the text has a non-empty `summary`, THE SYSTEM SHALL show it under "Giới thiệu" (Introduction); WHEN it is empty, THE SYSTEM SHALL show no such block. (FR-STR-004)
18. WHEN the text has titles in other languages, `author`, `han_translator` (with `han_translation_year`) or `reference_note`, THE SYSTEM SHALL show them in a "Thông tin" (Information) block, one labelled row per non-empty value, and leave out every empty one. (FR-STR-004, BR-STR-07)
    > ⚠️ Not confirmed (product): the exact copy of the row labels ("Tác giả" (Author), "Dịch giả Hán" (Chinese translator), "Ghi chú tham chiếu" (Reference note), "Tên (Pāli)" …) — product Appendix A item 11 covers labels; the default Vietnamese labels of `AS-SutraDetail-002` stand until changed.
19. THE SYSTEM SHALL show, for each version in the order received, a block with its name, the translator, the source name (tappable when `source_url` is an `http` / `https` URL, opened in Safari), the licence label of criterion 20, the source's own licence statement (`license_note`) and licence link (`license_url`, `http` / `https` only), the note, and the number of lines; empty values SHALL NOT be shown. (FR-STR-004, BR-STR-07, BR-STR-06)
20. THE SYSTEM SHALL show the licence of a version as "CC0" for `CC0-1.0`, "CC BY-NC 4.0" for `CC-BY-NC-4.0`, "Phạm vi công cộng" (Public domain) for `PUBLIC_DOMAIN` and "Được sao chép tự do" (Free to copy) for `COPY_ALLOWED`; WHEN the licence is `UNKNOWN`, absent or a code the app does not know, THE SYSTEM SHALL show no licence line (the source's own statement, when there is one, is still shown); a licence SHALL never hide or block a text. (BR-STR-07)
21. WHILE the text is unreviewed (`review_status` is present), THE SYSTEM SHALL show one short notice "Nội dung chưa được người am hiểu duyệt" (The content has not yet been checked by someone knowledgeable) in its own block; THE SYSTEM SHALL NOT show the notice for a text marked reviewed. (BR-STR-07, FR-STR-004)
    > ⚠️ Not confirmed (contract): which `review_status` value means "reviewed" — the contract defines only `UNREVIEWED` (`SutraDetail.review_status`); until the backend names it, any present status shows the notice (as built) — blocks only hiding the notice; hand back to the backend in innerlamp-be.
22. WHEN the text is linked to Buddhas or bodhisattvas, THE SYSTEM SHALL list them under "Phật & Bồ Tát liên quan" (Related Buddhas & bodhisattvas) in the order received (the server sends subject, speaker, mentioned), each row with the deity's name, its role label ("Chủ thể" (Subject), "Thuyết giả" (Speaker), "Được nhắc đến" (Mentioned)) and its thumbnail (`thumbnail_url`, a neutral placeholder when empty); WHEN none is linked, THE SYSTEM SHALL show no such section. (FR-STR-008, BR-STR-09)
23. WHEN the user taps a linked deity, THE SYSTEM SHALL open that deity's page by `deity_id`. (FR-STR-008)
24. WHEN the text has sections in its opening version, THE SYSTEM SHALL show "Mục lục" (Contents) with each section's name and line count, and WHEN the user taps a section, open the reading view at that section's first line; WHEN it has none, THE SYSTEM SHALL show no contents. (FR-STR-004, FR-STR-005)
25. WHEN the user taps "Đọc kinh" (Read), THE SYSTEM SHALL open the reading view on the version of criterion 31 from its first line. (FR-STR-004, FR-STR-005)
26. THE SYSTEM SHALL show on the sutra page no play button, no progress card, no narrator and no "Tải về máy" (Download) action. (BR-STR-12, FR-STR-004)
27. WHEN the request answers `404 SUTRA_NOT_FOUND`, THE SYSTEM SHALL show a not-found state with a way back and no "Thử lại"; WHEN it fails otherwise, THE SYSTEM SHALL show the error state (offline variant when there is no connection) with "Thử lại" that requests the text again — never only a transient message over a blank page, never a sample text. (FR-STR-004, FR-STR-011)
28. WHEN the user taps back, THE SYSTEM SHALL close the sutra page. (platform)

### The reading view ("Tụng kinh")

29. WHEN the reading view opens, THE SYSTEM SHALL show the header (back, title, "Aa" (font size) and, when the text has sections, the contents control), request page 1 of `GET /v1/sutras/{id}/lines?translation=<key>` for the opening version without signing in (the page that holds the chosen section's first line when opened from the contents), and show the lines in order from the first (or chosen) line. (FR-STR-005, BR-STR-13, NFR-STR-01)
30. THE SYSTEM SHALL show each line's `text` exactly as received — no gloss, no bell or wooden-fish cue, no opening ritual, no spelling or wrapping change that alters a word — and a heading row with the section's name where the section changes between two consecutive lines; the heading is not a line. (BR-STR-06, FR-STR-005)
31. THE SYSTEM SHALL open the version chosen by the product rule: among the Vietnamese versions, translation, then chant, then meaning, then poem, equal variants in the order received; all `rules/sutra-default-version.json` cases SHALL pass. (BR-STR-05, FR-STR-005)
    > ⚠️ Not confirmed (product): which version opens for a text that has no Vietnamese version (product Appendix A item 5) — blocks that case in `tasks.md` Phase 2; until answered the first version in the order received opens, recorded as an Assumption when implemented.
32. WHEN the user reads within about 40 lines of the last loaded line and more pages exist, THE SYSTEM SHALL request the next page of the same version (the same `page_size` on every call of a version), append its lines and show a loading line meanwhile; THE SYSTEM SHALL never have two requests for the same text in flight, and SHALL request nothing after `page >= total_pages` or an empty page. (FR-STR-005, NFR-STR-01, platform)
33. WHEN the user opens the contents and chooses a section, THE SYSTEM SHALL request the page that holds the section's `start_n` (`floor((start_n − 1) / page_size) + 1`), drop the lines before `start_n`, show the section from its first line and continue loading forward from there. (FR-STR-005)
    > ⚠️ Not confirmed (product): whether the apps show one section at a time like the website or scroll the whole text continuously (product Appendix A item 7) — blocks the final reading layout; this spec builds a continuous list that starts at the chosen section, with the contents as the way back to earlier sections.
34. WHEN the text has more than one version, THE SYSTEM SHALL offer a version switch in the reading view; WHEN the user chooses another version, THE SYSTEM SHALL request page 1 of that version, show its lines from their first line and the contents of that version; WHEN the text has one version, THE SYSTEM SHALL offer no switch. (FR-STR-006, BR-STR-05, BR-STR-06)
    > ⚠️ Not confirmed (product): whether iOS offers the version switch in this release and how a version is named to a visitor (product Appendix A item 6) — blocks the final switch and its labels; the names are built from the variant ("Bản dịch" (Translation), "Bản tụng" (Chant), "Giải nghĩa" (Meaning), "Bản thơ" (Poem)) and the language until answered.
35. WHEN the user taps "Aa", THE SYSTEM SHALL show the font-size choice of four sizes; WHEN the user picks one, THE SYSTEM SHALL apply it to the lines at once, remember it on the device and open the next text at that size. (FR-STR-007, BR-STR-11)
36. THE SYSTEM SHALL use for the reading view's font size the same stored choice as the "Cỡ chữ kinh văn" (Sutra font size) setting, so a size chosen in the reading view is selected in the settings and the other way round. (FR-STR-007, BR-STR-11)
37. THE SYSTEM SHALL draw the reading view on the app's light or dark appearance and offer no separate reading background ("Mặc định", "Vàng cát", "Đen OLED" are removed). (BR-STR-11, FR-STR-007)
38. THE SYSTEM SHALL show in the reading view no play / pause, no seek, no pace choice, no progress, no elapsed time, no narrator or "Đang tụng" (Chanting) status, no auto-scroll with a highlighted line and no keep-screen-awake override. (BR-STR-12)
    > ⚠️ Not confirmed (product): what the reading view offers while there is no audio — nothing, or the auto-scroll with a highlighted line at a chosen pace (product Appendix A item 4) — blocks any reading control beyond the contents, the version switch and "Aa"; iOS builds none until answered.
39. WHEN page 1 cannot be loaded, THE SYSTEM SHALL show the error state (offline variant when there is no connection) with "Thử lại" and no sample text; WHEN the response is `404 SUTRA_NOT_FOUND` or `404 TRANSLATION_NOT_FOUND`, THE SYSTEM SHALL show the not-found state with a way back; WHEN a later page fails, THE SYSTEM SHALL keep the lines already shown and show "Thử lại" at their end. (FR-STR-011, platform)
40. WHEN the user opens the longest text (6,967 lines), THE SYSTEM SHALL show its first lines without loading the whole text, within 2 s on a 4G connection (checked by manual QA on a device). (FR-STR-005, NFR-STR-01)
41. WHEN the user taps back, THE SYSTEM SHALL close the reading view and return to the sutra page. (platform)

### Quote of the day ("Câu kinh mỗi ngày")

42. THE SYSTEM SHALL choose the quote of a date as the quote numbered (day of the year of that **Gregorian** date, 1–366, modulo the number of quotes) + 1 in the quote file, using a Gregorian calendar whatever the device's region calendar and the device's time zone; all `rules/sutra-daily-quote.json` cases SHALL pass. (BR-STR-10, FR-STR-010)
43. WHEN Home loads, THE SYSTEM SHALL show on its large lunar card the quote of today's device date — never a random one — the same however often Home is opened that day, and WHEN the device date changes while the app is running, THE SYSTEM SHALL show the new date's quote the next time Home appears. (FR-STR-010, BR-STR-10; date change: platform)
    > ⚠️ Not confirmed (product): whether the large Home card keeps the quote of today's date when the user selects another day in the week strip (as built) or follows the selected day — FR-STR-010 says "for that date" without saying which — blocks only the week-strip case of `tasks.md` Phase 6; hand back to ba-writer in innerlamp-be.
44. WHEN the lunar-day page opens for a date (from Home or from the lunar calendar), THE SYSTEM SHALL show the quote of that date's Gregorian date, not the quote the caller was showing. (FR-STR-010, BR-STR-10)
45. THE SYSTEM SHALL show with a quote its verse text and its attribution — the sutra "Kinh Pháp Cú", the translator, the chapter and the verse number. (BR-STR-10)
    > ⚠️ Not confirmed (product): the layout and copy of the attribution line (today "— Kinh Pháp Cú (Dhammapada), câu 5" with no translator or chapter) — blocks the attribution copy of `tasks.md` Phase 6; the three facts are added to the line until the copy is given.
46. WHEN the quote file cannot be read or holds no quote, THE SYSTEM SHALL show the built-in fallback verse on the card and fail nothing else on the screen. (FR-STR-010, platform)
    > ⚠️ Not confirmed (product): whether the card shows a built-in fallback line (as built) or nothing when the quote file cannot be read (product Appendix A item 14) — blocks the quote block's failure behaviour; the fallback stays until answered.
    > ⚠️ Not confirmed (product): where the 300 quotes live — bundled in the app as today, or served by the backend (product Appendix A item 3). The bundled file `InnerLamp/Resources/Data/sutra_quotes_300.json` is excluded from git by the repo's `*.json` ignore rule, so a fresh checkout has no quote file and shows the fallback — blocks a reproducible build of the quote block.

### Related sutras on the deity page

47. WHEN the user taps a related sutra on a deity's page, THE SYSTEM SHALL open that text's sutra page by its server `id`; the list itself (request, order, section) is `Docs/Specs/Deity/` criteria 25–27. (FR-STR-009, BR-STR-09)

### Platform

48. THE SYSTEM SHALL show the interface of this feature in Vietnamese whatever the app language, with the Vietnamese title of each text. (BR-STR-05)
49. WHEN the user changes a chip or the search term on a 4G connection, THE SYSTEM SHALL show the first page within 2 s (checked by manual QA on a device). (NFR-STR-02)
50. WHEN the unit tests run, THE SYSTEM SHALL pass every case of the product vector files `rules/sutra-default-version.json` and `rules/sutra-daily-quote.json` against the app functions that pick the opening version and the quote number. (BR-STR-05, BR-STR-10)

## Error → UI mapping

Operations are cited, not copied; the contract is innerlamp-be `docs/specs/api/openapi.yaml` (tag Sutras).
There is no cached copy in any case (`design.md` "Caching").

| Operation | Failure case | What the user sees |
|---|---|---|
| `GET /v1/sutras` page 1 (open, chip, term, "Thử lại") | any failure (offline, unreachable, `500`, undecodable) | error state (offline variant when offline) with "Thử lại" in place of the list (criterion 11) |
| `GET /v1/sutras` page 1 | `items` empty, `total` 0 | the empty state of criterion 12 (library empty / no chip match / no search match) |
| `GET /v1/sutras` page > 1 | any failure | texts kept, loading removed, "Thử lại" at the end (criterion 13) |
| `GET /v1/sutras` | `400 INVALID_PAGE`, `400 INVALID_FILTER` | same as the other failures (the app never sends such values — a bug, logged, not a user error) |
| `GET /v1/sutras/{id}` | `404 SUTRA_NOT_FOUND` | not-found state with a way back, no "Thử lại" (criterion 27) |
| `GET /v1/sutras/{id}` | any other failure | error state (offline variant) with "Thử lại" (criterion 27) |
| `GET /v1/sutras/{id}/lines` page 1 | `404 SUTRA_NOT_FOUND`, `404 TRANSLATION_NOT_FOUND` | not-found state with a way back (criterion 39) |
| `GET /v1/sutras/{id}/lines` page 1 | any other failure | error state (offline variant) with "Thử lại" (criterion 39) |
| `GET /v1/sutras/{id}/lines` page > 1 | any failure | lines kept, "Thử lại" at their end (criterion 39) |
| `GET /v1/sutras/{id}/lines` | `400 INVALID_TRANSLATION`, `400 INVALID_PAGE`, `400 INVALID_PAGE_SIZE` | same as the other failures (a bug, logged) |
| deity thumbnail URL | any failure | neutral placeholder, no message (criterion 22) |
| quote file | missing, unreadable, empty | the fallback verse (criterion 46) |

## Out of scope (this feature boundary, not backend work)

- The library hub tab and its tiles / groups ("Thư viện"), the downloads view and the audio player —
  separate later specs (`Docs/Specs/Library/`, `Docs/Specs/Downloads/`, `Docs/Specs/Player/`; product §1.2).
  Until the Library spec lands, its sample tiles (ids such as `sutra.phapcu`) open the not-found state
  of criterion 27 instead of a wrong text.
- The deity page and its "Kinh liên quan" (Related sutras) list — `Docs/Specs/Deity/` (FR-DTY-007);
  only the tap target is here (criterion 47).
- The "Kinh nên tụng" (Sutras to recite) section of a festival — `Docs/Specs/Calendar/` (out of scope there).
- Audio, offline download, bookmarks, favourites, reading progress, chanting history, full-text search
  inside a text, sharing a verse card, back-office editing (product §1.2).
- The "Cỡ chữ kinh văn" row itself and the settings screens (`Docs/Specs/Language/`, `Docs/Specs/Settings/`);
  only the shared stored choice is here (criteria 35–36).
- Loading the library content (FR-STR-012, backend only).

## Pending (not yet implemented — see `tasks.md`)

- Real text in the reading view from `GET /v1/sutras/{id}/lines`, with section headings, paging,
  contents and jump, version switch (`tasks.md` Phase 2, 5; resolves `TD-SutraDetail-003`,
  `TD-Reader-001`, `TD-Reader-002`). **Today the reading view ignores the server id**: it looks the
  id up in a sample catalogue of 11 sutras and falls back to the first one (Kinh Pháp Cú), so a tap on
  "Đọc kinh" for any other text shows the wrong text (religious-content defect, product §2.5).
- Four remembered font sizes shared with the settings, the three backgrounds dropped (Phase 5;
  resolves `TD-Reader-003`, `TD-Language-002` for the reading view).
- Simulated playback, "Tự cuộn" (Auto-scroll) row, pace chips, cues and the app-made opening text
  removed (Phase 5; resolves `TD-Reader-001`).
- 60-minute chip, product labels and the card / page content of product §3.1.1 (Phase 3, 4).
- Default version by the product rule instead of "first Vietnamese in server order" (Phase 2).
- Licence labels, per-version facts, the short unreviewed notice, linked deities that open the deity page
  (Phase 4).
- Error, empty and not-found states with "Thử lại" on all three screens, replacing transient messages
  (Phase 3, 4, 5).
- Quote of the day by date on Home (random today), Gregorian calendar, attribution with translator and
  chapter, no handed-over quote on the lunar-day page (Phase 6).
- Product vectors, build / test run on a device, manual QA and documentation (Phase 7–9).
- Product Appendix A items 1 and 2 (content review, licence clearing) block public release of the
  content, not this spec.

## Open questions (resolved)

- ~~Can the topic and the duration chips combine (`Docs/Specs/Sutras/` v1.2 ⚠️, `AS-Sutras-002`)?~~ → Yes: one topic chip and one duration chip, both applied (BR-STR-03). Resolved 2026-10-15 by product spec v1.0. (The built app already sends both; the drift is the missing 60-minute chip and the labels.)
- ~~What does search match (`AS-Sutras-001`)?~~ → Any title, the collection and the citation code, ignoring case and diacritics, on the server; the summary and lines are never searched (BR-STR-04). Resolved 2026-10-15 by product spec v1.0.
- ~~Which title and which version does iOS show (`AS-Sutras-003`)?~~ → Vietnamese title and the version of the BR-STR-05 rule. Resolved 2026-10-15 by product spec v1.0.
- ~~Show a deity row as plain text or open the deity page (`AS-SutraDetail-002`)?~~ → It opens the deity page (FR-STR-008). Resolved 2026-10-15 by product spec v1.0.
- ~~Wording of the unreviewed notice (`AS-SutraDetail-002`)?~~ → "Nội dung chưa được người am hiểu duyệt" (BR-STR-07). Resolved 2026-10-15 by product spec v1.0. (The value that means "reviewed" is a contract question, criterion 21.)
- ~~How to show licence, source and the API fields the page did not use (`AS-SutraDetail-001`, `-002`)?~~ → Translator, source and licence per version, unknown licence hidden, empty values hidden (BR-STR-07). Resolved 2026-10-15 by product spec v1.0.
- ~~What audio, narrator, progress and per-section duration does the page show (`TD-SutraDetail-002`, `AS-Reader-001…003`, `TD-Reader-001`)?~~ → None: no text has audio and the product offers no player or timer-driven highlight (BR-STR-12). Resolved 2026-10-15 by product spec v1.0.
- ~~Is there a text API for the reader (`Docs/Specs/Reader/` v1.1 ⚠️)?~~ → Yes, `GET /v1/sutras/{id}/lines` in `openapi.yaml`. Resolved 2026-10-16 by reading the contract at a8a016b.
- ~~Does the reader start at a chosen part, and are the preferences kept (`Docs/Specs/Reader/` Pending, `TD-Reader-003`)?~~ → Yes: jump to a section (FR-STR-005) and one remembered, shared font size (BR-STR-11). Resolved 2026-10-15 by product spec v1.0.
- ~~Is `.openPlayer` wired (`Docs/Specs/SutraDetail/` v1.0)?~~ → Wired in the old code; removed from the page by criterion 26. Resolved 2026-10-16.

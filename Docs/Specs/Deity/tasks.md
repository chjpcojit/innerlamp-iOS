# Tasks — Deity

Version: 1.0
Last updated: 2026-10-15
Status: in-progress — Phase 1 (what is built and still matches product v1.0) done; Phase 2–8 pending; Phase 2 and the vía tasks of Phase 3, 4 and 6 blocked on backend deity v3.0 + `openapi.yaml`; several copy tasks blocked on product ⚠️

> See `changelog.md` in this folder for the version history of this spec.

> Every item traces to a row of `design.md` "Layers & components" or a step of its Step-by-step Flows.
> `[x]` = verified in the code on 2026-10-15 **and** matching this spec v1.0; work that exists but no
> longer matches product v1.0 is listed as a `[ ]` change task instead.

## Phase 1 — Built and kept (retroactive record)

- [x] Home block "Thư viện Phật & Bồ Tát" and Library block "Chư Phật & Bồ Tát": featured cards from `GET /v1/deities/top` in server order through the shared `ILHomeDeityCarouselView`; loading skeleton; failure does not fail the screen (criteria 1 without `date`, 3 non-fatal part)
- [x] Block "Xem tất cả" and Library tile "Phật & Bồ Tát" → `ILDeitiesCoordinator`; card tap → `ILDeityCoordinator` (criterion 2)
- [x] `TopDeitiesEndpoint`, `DeitiesPageEndpoint` (page only), `DeityDetailEndpoint`, `ILDeitySummaryDTO`, `ILDeityDTO`, `ILDeityMapper`, `ILDeityCatalogRepository` + `ILDeityCatalogRepositoryImpl`, `ILDeityCatalogLocalDataSource` (Core Data), `ILCatalogError` mapping
- [x] Top and detail network-first with cached copy on failure (criterion 30 for top / detail)
- [x] Catalogue shell: `ILDeitiesCoordinator`, `ILDeitiesViewController` (sticky header band + `ILNavBar` + chips "Tất cả · Chư Phật · Bồ Tát", no "Chư Thiên" chip), `ILDeitiesGridView`, `ILDeitiesCardView` (thumbnail, else image, else placeholder; type badge; name; core virtue), `ILDeitiesSkeletonView`, card tap → deity page, back (criteria 4 image / name part, 7 chips, 11)
- [x] Deity page shell: `ILDeityCoordinator` (leaf: back, festivals, mala with text, share sheet, sutra), `ILDeityViewController`, `ILDeityHeroView` (image + type label + pure land), loading, error and offline states with "Thử lại" (criteria 12 without `date`, 13 error branch, 23)
- [x] Biography collapsed with "Đọc thêm" / "Thu gọn" only on overflow (criterion 16)
- [x] Vows numbered from 1, first 5 + "Xem đủ N đại nguyện" / "Thu gọn" (criterion 17, BR-DTY-07)
- [x] Mantra cards "Danh hiệu" / "Thần chú" (Sino-Vietnamese + Sanskrit) / "Đà-la-ni" (excerpt + name), a card without text left out (criterion 19 cards part, BR-DTY-04)
- [x] Mala opens with the given text (`.openMala(mantraText:)`); system share sheet (`.share(text:)`)
- [x] DI: `DIContainer.makeDeity*`, `makeDeities*`, `makeDeityCatalogRepository`
- [x] Unit tests written: `ILDeityViewModelTests` (+ `ILDeityUseCaseTests`), `ILDeitiesViewModelTests`, `ILDeityCatalogRepositoryTests`, Home / Library deity tests (they test the old behavior and are rewritten in Phase 2–7)

## Phase 2 — Contract adoption (blocked: backend deity v3.0 Phase 8–10 + `openapi.yaml` update, Phase 9 there)

- [ ] Confirm in innerlamp-be `docs/specs/api/openapi.yaml` that the deity routes have `date`, `next_via` (summary + detail), `via_events` (detail), page size 12 and `INVALID_DATE`; update the `Contract:` line of `requirements.md` and drop the "contract not yet in openapi.yaml" notes of `design.md`
- [ ] Entity: `ILDeityViaEntity`, `ILDeityViaEventEntity`; `nextVia` on `ILDeitySummaryEntity` and `ILDeityEntity`; `viaEvents` on `ILDeityEntity`
- [ ] DTO: `ILDeityViaDTO`, `ILDeityViaEventDTO`; optional `next_via` / `via_events`; stop decoding `lunar_memorial_days` (deprecated, backend AC 30)
- [ ] `ILDeityMapper`: vía DTO → entity (`YYYY-MM-DD` → y/m/d, invalid → `nil`)
- [ ] Endpoints: `date` on `TopDeitiesEndpoint`, `DeitiesPageEndpoint`, `DeityDetailEndpoint` (device date, `en_US_POSIX` `yyyy-MM-dd` in the device time zone)
- [ ] `ILDeityCatalogLocalDataSource`: store `next_via` / `via_events`, `image_url` (resolves TD-Deity-001) and the request date with cached rows; lightweight migration
- [ ] Stale next vía in an offline copy (criterion 32) — blocked on ⚠️ (product)
- [ ] `ILDeityCatalogRepositoryTests`: `date` sent on the three routes, vía fields decoded / absent, old cached copy without vía still decodes

## Phase 3 — Catalogue: server filter and pages (FR-DTY-002, FR-DTY-003, FR-DTY-010, NFR-DTY-01/02)

- [ ] `ILCatalogPageEntity.total` (shared with Temple — skip if already added) and `DeitiesPageEndpoint` `type` query item (only for "Chư Phật" / "Bồ Tát") (criteria 5, 7)
- [ ] `ILDeityCatalogRepository.loadDeities(page:kind:today:)`; repository list pages network-first, store and fall back only for unfiltered pages, reset on a `page_size` / `total` change, `404` evicts a cached detail ("Caching"; criteria 13, 30–32)
- [ ] Rewrite `ILDeitiesUseCase` to `loadPage(_:kind:)` (one page) — removes `loadAllPages`, the 50-page cap, the `top` fallback, `uniqued` and `deities(in:kind:)`; delete `ILDeitiesEntity`
- [ ] Rewrite `ILDeitiesViewModel`: chip state, cancel in-flight + drop stale responses, page cursor + `hasMore`, in-flight guard, append-only cards de-duplicated by `id`, subtitle N from `total` of the current chip (criteria 5–8)
- [ ] `ILDeitiesViewController`: load-more trigger near the end of the grid; footer loading / "Thử lại" for a failed later page; incremental append in `ILDeitiesGridView` (AGENTS.md §4.6) (criteria 6, 10)
- [ ] Empty / error state: one prototype state "Chưa có thông tin chư Phật" + hint + "Thử lại" + "Xem lịch lễ vía" (replaces "Đang cập nhật" and the separate error state); `ILDeitiesNavEvent.openFestivals` + coordinator → Festivals (criterion 9)
- [ ] Filtered-empty copy (criterion 9 marker) — blocked on ⚠️ (product)
- [ ] Card vía line "Vía dd/MM âm lịch" from `nextVia`, none when `nil`; remove the "Ngày vía: đang cập nhật" placeholder (criterion 4) — needs Phase 2; leap marker blocked on ⚠️ (product)
- [ ] `ILDeitiesViewModelTests`: first page + count, next page append + stop, chip → page 1 with `type`, "Tất cả" → no `type`, stale response dropped, later-page failure keeps cards, empty state actions

## Phase 4 — Deity page alignment (FR-DTY-004…006, FR-DTY-008, FR-DTY-009, BR-DTY-01, 04, 06, 08)

- [ ] `deity.kind.deva` → "Chư Thiên" (BR-DTY-01; used by cards, page and blocks through `kindLabel(for:)`)
- [ ] Footer `deity.footnote` without "· Báo thông tin sai" (criterion 20, BR-DTY-08)
- [ ] Not-found state for `ILCatalogError.notFound`: message + back, no "Thử lại" (criterion 13)
- [ ] Name block: honorific title, Sanskrit name and Chinese name as text, each hidden when empty (criteria 14, 15)
- [ ] Core virtue + canonical source line; delete `ILDeityEntity.canonicalSources` (criterion 14)
- [ ] "Hình tượng" section: `Views/ILDeityIconographyView.swift` with posture, seat or mount, sacred objects, symbolic meaning, rows hidden when empty, section hidden when all are (criterion 18) — row labels blocked on ⚠️ (product)
- [ ] One "Trì niệm với tràng hạt" + one "Chia sẻ" action under the mantra cards (remove the per-card buttons of `ILDeityMantraCardView`); chant only with a short mantra, passing `short_mantra_sino_vietnamese` (criteria 19, 28)
- [ ] Share text: name, short mantra Sino-Vietnamese, Sanskrit, missing values left out (criterion 29) — link in the text blocked on ⚠️ (product Appendix A item 3)
- [ ] Vía card from `nextVia`: name, lunar day, month "THÁNG GIÊNG" / "THÁNG n" / "THÁNG CHẠP" + "nhuận", solar date with weekday (device calendar), countdown via `ILCalendarRules.countdown` (criterion 21) — needs Phase 2
- [ ] Vía list from `viaEvents` in the order received (criterion 22) — needs Phase 2; rows without occurrence blocked on ⚠️ (product)
- [ ] Delete `upcomingMemorialDay`, `nextOccurrence`, the 400-day window, the UTC+7 calendar, `ILDeityUpcomingMemorialDayEntity`, `ILDeityMemorialDayEntity`, `primaryMemorialDay` (Entity + `ILHomeUseCaseImpl`) — same release as Phase 2 ("Deliberately stubbed for now")
- [ ] Reload on re-appear when the device date changed since the last load (criterion 24)
- [ ] `ILDeityViewModelTests`: section order and hiding, not-found vs error, single action row, chant text, share text, vía card from `nextVia` (none when `nil`), countdown labels, reload on a new date

## Phase 5 — Related sutras (FR-DTY-007)

- [ ] `DeitySutrasEndpoint` (`GET /v1/deities/{id}/sutras?page=1`), sutra DTO reading `id` + `titles.vi`, `ILDeityRelatedSutraEntity` (new shape), `ILDeityCatalogRepository.loadRelatedSutras(deityID:)` (not cached)
- [ ] `ILDeityUseCase.loadRelatedSutras(id:)`; delete `relatedSutras(for:)` and `librarySutraIDs`
- [ ] `ILDeityViewModel`: load in parallel with the detail, rows in the order received, no section when empty or failed, `.openSutra(id)` with the server id; remove `deity.sutra.pending` / `available` / `open` subtitles (criteria 25–27)
- [ ] Order and paging of the section — blocked on ⚠️ (product) (criterion 25 markers); failure behavior ⚠️ (criterion 27)
- [ ] Tests: rows from the endpoint, empty → hidden, failure → hidden and page unaffected, tap → `.openSutra(id)`

## Phase 6 — Home / Library blocks (FR-DTY-001, FR-DTY-010)

- [ ] `ILHomeUseCaseImpl.makeDeity(from:)` carries `nextVia`; `ILHomeDeityModel` vía line "Vía dd/MM âm lịch" from it, none when `nil`; remove `home.deity.memorialUpdating` (criterion 4) — needs Phase 2
- [ ] `date` on the `top` call for Home and Library (criterion 1) — needs Phase 2
- [ ] Block empty state (copy, retry or not) for "no deity" and "failed" (criterion 3) — blocked on ⚠️ (product)
- [ ] `ILHomeViewModelTests` / `ILLibraryViewModelTests`: vía line, empty state, no fake cards

## Phase 7 — Remove the dead bundled catalogue

- [ ] Delete `ILDeityUseCase.getAllDeities()` and the static 18-item `makeCatalog()`; update the stale `getAllDeities` comments in `ILHomeEntity.swift` / `ILLibraryEntity.swift`
- [ ] Delete `ILDeityRepository` (+ `ILDeityError`), `ILDeityRepositoryImpl`, `ILDeityLocalDataSource`, `ILDeityMO` (and its Core Data entity if nothing else uses it), `DIContainer.deityLocalDataSource` / `makeDeityRepository`, `InnerLampTests/ILDeityRepositoryTests.swift`; drop the `phat_botat.json` references in doc comments (`ILDeityDTO`, `ILDeityEntity`, `ILDeityCatalogRepository`)
- [ ] Rewrite the test helpers that build deities from `getAllDeities()` (`ILDeityViewModelTests`)

## Phase 8 — Product vectors, verification, documentation

- [ ] `Scripts/sync-product-vectors.sh` (create or extend) copies `../innerlamp-be/docs/product/deity/rules/deity-next-via.json` into `InnerLampTests/ProductVectors/deity/` with a `SOURCE` file; add it to the test target resources
- [ ] `ILDeityProductVectorTests`: every case of `deity-next-via.json` (BR-DTY-06) — countdown days + label through `ILCalendarRules.countdown`, and `next_via: null` → no vía card (design "Product vectors"); `deity-order.json` is backend-only
- [ ] Build (`xcodebuild build`, `generic/platform=iOS`) and test run (physical device per AGENTS.md); record the result here
- [ ] Close `Docs/Assumptions/Deity/AS-Deity-DEVA-label.md` as Invalidated by BR-DTY-01 ("Chư Thiên") once Phase 4's label change lands; resolve `Docs/Tech-Debt/Deity/TD-Deity-001` with Phase 2's `image_url` column
- [ ] `InnerLamp/Presentation/Scenes/Deity/README.md` and `Deities/README.md`: status tables + changelog for these changes, and a pointer to `Docs/Specs/Deity/`
- [ ] `Docs/Knowledge/features/deity.md` (OKF) — with `okf-writer` after Phase 2–7 are verified on device
- [ ] Manual QA on device against prototype screens `buddhas`, `buddhasEmpty`, `buddha` and the home / library blocks

## Deferred (separate features, not blocking Deity)

- Countdown rule `ILCalendarRules` — owned by `Docs/Specs/Calendar/` (used here, created by whichever lands first).
- Sutra page — `Docs/Specs/SutraDetail/`; mala — `Docs/Specs/Mala/`; festival calendar — `Docs/Specs/Calendar/`.
- Dedicated share layout (prototype share screen) — out of scope (product §1.2).

# Tasks — Temple

Version: 3.1
Last updated: 2026-10-15
Status: in-progress — Phase 1 (what is built and still matches product v1.1) done; Phase 2–8 pending; Phase 2–3 and the new-field tasks of Phase 4 blocked on the backend contract; Phase 5 location tasks blocked on a product ⚠️

> See `changelog.md` in this folder for the version history of this spec.

> Every item traces to a row of `design.md` "Layers & components" or a step of its Step-by-step Flows.
> `[x]` = verified in the code on 2026-10-15 **and** matching this spec v3.0; work that exists but no
> longer matches product v1.1 is listed as a `[ ]` change task instead.

## Phase 1 — Built and kept (retroactive record)

- [x] Home block: featured cards from `GET /v1/temples/top` in server order (`ILHomeUseCase.loadTopTemples`, `ILHomeViewModel.loadTopTemples`); failure or empty → "updating" placeholder, Home not failed (criteria 1–2)
- [x] Home block header "Xem tất cả" (`home.temple.viewAll`) → `.openTemples` → `ILHomeCoordinator.showTemples()`; card tap → `ILTempleCoordinator` (criterion 3)
- [x] `TopTemplesEndpoint`, `TempleDetailEndpoint`, `TemplesPageEndpoint` (page only), `ILTempleDTO`, `ILTempleMapper`, `ILTempleRepository` + `ILTempleRepositoryImpl`, `ILTempleLocalDataSource` (Core Data), `ILCatalogError` mapping
- [x] Top and detail network-first with cached copy on failure; `404` evicts the cached detail (criterion 37, "Caching")
- [x] Directory screen shell: `ILTemplesCoordinator`, `ILTemplesViewController` (`ILStickyHeaderBand` + `ILNavBar` + `ILSearchInputView` + region chips "Tất cả · Miền Bắc · Miền Trung · Miền Nam" via `ILTempleFinderRegionFilter`), `ILTemplesRowCell`, error state with offline title + "Thử lại", empty text "Không tìm thấy chùa" + hint, card tap → temple page, back (criteria 8 chips, 10, 12 first page, 13)
- [x] Temple page shell: `ILTempleCoordinator` (leaf), `ILTempleViewController`, `ILTempleHeroView`, `ILTempleStatusCardView`, `ILTempleSkeletonView`; loading, error and offline states with "Thử lại" (criteria 15, 16 error branch)
- [x] Sections in prototype order with missing values kept as "Đang cập nhật" / "Không có": hero chips + name + "Còn gọi" hidden without aliases, facts grid, collapsible introduction ("Đọc thêm" / "Thu gọn" only on overflow), abbot + founder, architecture text, four API amenities, visiting notes numbered "01, 02, …", location (address, region, coordinates), contact rows (criteria 17 order, 18, 20 four tiles, 21, 22)
- [x] Google Maps ("Chỉ đường" + button) and Apple Maps directions to the coordinates; contact row without value does nothing (criteria 32, 34 no-value branch)
- [x] DI: `DIContainer.makeTemple*`, `makeTemples*`, temple repository
- [x] Unit tests written: `ILTempleViewModelTests`, `ILTempleUseCaseTests`, `ILTempleRepositoryTests`, `ILTemplesViewModelTests` (they test the old behavior and are rewritten in Phase 3–4)

## Phase 2 — Contract adoption (blocked: backend v2.0 Phase 11–13 + `openapi.yaml` update)

- [ ] Confirm in innerlamp-be `docs/specs/api/openapi.yaml` that `GET /v1/temples` has `q`, `region`, page size 12, and `TempleDetail` has `holiday_operating_hours`, `sangha_body`, `contacts`, `content_updated_month`; update the `Contract:` line of `requirements.md`
- [ ] DTO: add `location.province`, `ward`, `full_address` (summary + detail) and the four detail fields, all optional for old cached copies
- [ ] Entity: location `province`, `ward?`, `fullAddress`; detail `holidayOperatingHours`, `sanghaBody`, `ILTempleContactsEntity`, `contentUpdatedMonth`
- [ ] `ILTempleMapper`: map the new fields (trim, `nil` → empty, `YYYY-MM` → year / month or `nil`)
- [ ] `ILTempleDirectoryQuery` (trim, cut to 100 characters, empty → `nil`) (criterion 7)
- [ ] `TemplesPageEndpoint`: send `q` / `region` only when set (criteria 7–8)
- [ ] `ILTempleRepository.loadTemples(page:query:)` with default "no query"; `ILCatalogPageEntity` gains `total`
- [ ] `ILTempleRepositoryImpl`: directory pages network-first; store and fall back only for unfiltered pages (criteria 37–38, "Caching")
- [ ] `ILTempleRepositoryTests`: query parameters sent, unfiltered fallback, no fallback for search / region, old cached detail without the new fields still decodes

## Phase 3 — Directory: server search, region filter, pages (FR-TPL-002…004, NFR-TPL-01/02)

- [ ] Rewrite `ILTemplesUseCase` to `loadPage(_:query:)` (one page, no loop) — removes the "load every page" path
- [ ] Rewrite `ILTemplesViewModel`: query state, 400 ms debounce on the term, immediate region change, cancel in-flight + drop stale responses, page cursor + `hasMore`, in-flight guard, append-only rows de-duplicated by `id`, subtitle from `total`; remove the device-side `normalize` filter (criteria 4–10)
- [ ] `ILTemplesViewController`: load-more trigger near the end of the table; list footer loading / "Thử lại" for a failed later page; incremental row insert (AGENTS.md §4.6) (criteria 5, 12)
- [ ] Search placeholder `temples.search.placeholder` — name only (criterion 11) — blocked on ⚠️ (product) placeholder wording
- [ ] `ILTemplesViewModelTests`: first page + count, next page append + stop, search → page 1 with `q`, clear → no `q`, 100-character cut, region + search combined, "Tất cả" → no `region`, stale response dropped, later-page failure keeps rows

## Phase 4 — Temple page alignment (FR-TPL-006…009, BR-TPL-06, 08, 09)

- [ ] Remove follow (button, `followTapped`, `isFollowing`, `ILTempleUseCase.toggleFollow` stub, `errorMessage` output if unused), offering (button, `offerTapped`, `.offer`) and the "Báo thông tin sai" footer label; delete their localization keys (criterion 24)
- [ ] Not-found state for `ILCatalogError.notFound`: message + back, no "Thử lại" (criterion 16)
- [ ] Hero image placeholder when `image_url` is `nil` or fails (today: image height 0) (criterion 18)
- [ ] Hero place line from `ward` + `province` (province only when `ward` is `nil`); location section uses `full_address` (criteria 17, 33)
- [ ] `ILTempleOpenStatus` (Domain): Vietnam calendar UTC+7, lunar day of the Vietnam date and of the next day, `"HH:MM - HH:MM"` parsing, zero-padded `HH:MM` labels; wire into `ILTempleViewModel`, replacing `parseOperatingHours` / `isOpen` / `formatMinuteOfDay` (criteria 25, 26 "Hôm nay")
- [ ] Hide the status line when there are no hours (today: "Chưa rõ giờ mở cửa"); hours "Đang cập nhật" (criterion 27)
- [ ] Rằm & Mùng Một row value when the temple has no holiday hours (criterion 26) — blocked on ⚠️ (product)
- [ ] Recompute the status on re-appear and on `UIApplication.willEnterForegroundNotification` (criterion 28)
- [ ] Fill "Giáo hội" from `sangha_body` and the four contact rows from `contacts`; open fanpage / website URLs **as received** (stop prefixing `https://`), `tel:` without spaces, `mailto:` (criteria 17, 34) — needs Phase 2
- [ ] Footer update month from `content_updated_month` (criterion 23) — needs Phase 2; copy blocked on ⚠️ (product)
- [ ] "Kinh sách" tile (criterion 20) — blocked on ⚠️ (product)
- [ ] Events section: empty state "Chùa chưa đăng sự kiện nào." without the follow hint; remove `eventsTapped`, `sessionTapped`, `.events`, `.session` and the "Xem tất cả" link of the section (criterion 35)
- [ ] `ILTempleCoordinator`: remove the `.offer` / `.events` / `.session` cases
- [ ] `ILTempleViewModelTests`: hidden actions, not-found vs error, status hidden without hours, new fields filled / missing, contact URLs as received, foreground recompute

## Phase 5 — Distance (BR-TPL-07)

- [ ] `ILTempleDistance` (Domain): haversine + label formatting (criterion 29)
- [ ] `ILUserLocationProviding` protocol + `ILUserLocationProvider` (`CLLocationManager`, When In Use, one-shot fix with timeout, nothing stored or logged) + `DIContainer` wiring (criteria 30–31) — blocked on ⚠️ (product) when to ask + purpose text
- [ ] `Info.plist` `NSLocationWhenInUseUsageDescription` — blocked on the same ⚠️
- [ ] `ILTempleViewModel`: distance line from the provider; hidden when `nil` / denied (criterion 29)
- [ ] Tests: ViewModel with a mock provider (granted, denied, no fix); provider never called before Step 1 success

## Phase 6 — Cards (§3.1.1)

- [ ] `ILTempleCatalogLabels.typeLabel` (open enum, unknown → humanised raw value)
- [ ] `ILTemplesRowCell` and `ILHomeTempleCarouselView` card: image (placeholder), name, type, province (from `location.province`), heritage rank, sect (criterion 14); `ILHomeTempleEntity` carries the needed fields
- [ ] Update `ILHomeViewModelTests` / `ILTemplesViewModelTests` for the card fields

## Phase 7 — Product vectors

- [ ] `Scripts/sync-product-vectors.sh` (create, or extend the Memorial one if it exists) copies `../innerlamp-be/docs/product/temple/rules/temple-distance.json` and `temple-open-status.json` into `InnerLampTests/ProductVectors/temple/` with a `SOURCE` file (commit sha + hashes); add the files to the test target resources
- [ ] `ILTempleProductVectorTests`: every case of `temple-distance.json` (BR-TPL-07) through `ILTempleDistance.label(km:)`
- [ ] `ILTempleProductVectorTests`: every case of `temple-open-status.json` (BR-TPL-09) through `ILTempleOpenStatus` with `now_utc` injected, also run with the process time zone set to a non-UTC+7 zone
- [ ] Run the test target (`xcodebuild test`, physical device per AGENTS.md) — the target was blocked by the GRPC module errors in earlier versions; record the result here

## Phase 8 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Temple/README.md` and `Temples/README.md`: status tables + changelog for the v3.0 changes
- [ ] Close `Docs/Assumptions/Temples/AS-Temples-001` (region chips) as Validated by BR-TPL-04; set `TD-Temples-001` ("Đề xuất" action) per the out-of-scope decision (temple-suggestion)
- [ ] `Docs/Knowledge/features/temple.md` (OKF) — refresh with `okf-writer` after Phase 2–7 are verified on device
- [ ] Manual QA on device against prototype screens `temple`, `temples` and the home block

## Deferred (separate features, not blocking Temple)

- Follow a temple (later feature, product §1.2).
- Offering screen — `Docs/Specs/Offering/`.
- Temple events in the events section — `sangha` (`Docs/Specs/Sangha/`, `Docs/Specs/Events/`).
- Practice-temple picker still loading every page — `Docs/Specs/TempleFinder/` (TD-TempleFinder-002).
- Temple proposal — `Docs/Specs/TempleFinder/`, `Docs/Specs/AddTemple/` (`temple-suggestion`).
- ~~Deleting the legacy files `Docs/Specs/Temple/SRS.md` and `Docs/Specs/Temples/*`~~ — done in v3.1.

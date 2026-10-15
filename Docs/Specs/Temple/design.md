# Design — Temple

Version: 3.1
Last updated: 2026-10-15
Status: in-progress — home block, directory screen shell, temple page, detail/top/page endpoints and Core Data cache built against the old contract; planned: server search + region + paging, hidden actions, Vietnam-time open status with Rằm & Mùng Một hours, distance with location permission, new detail fields, not-found state, product vectors

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. Three entry surfaces share one Data layer
(`ILTempleRepository`):

- **Home block** — part of `Presentation/Scenes/Home/` (`ILHomeTempleCarouselView`), fed by
  `ILHomeUseCase.loadTopTemples()`.
- **Directory** — `Presentation/Scenes/Temples/` (`ILTemplesCoordinator`, child of
  `ILHomeCoordinator`). Code folder name stays `Temples` (product §1.5).
- **Temple page** — `Presentation/Scenes/Temple/` (`ILTempleCoordinator`, a leaf coordinator with no
  delegate), pushed by `ILHomeCoordinator`, `ILTemplesCoordinator`, `ILSanghaCoordinator`,
  `ILTempleFinderCoordinator` and the family-tree coordinators, always with a server temple `id`.

How iOS meets the product constraints (see `requirements.md` "Constraints"):

- **Server does order / search / filter / paging** (BR-TPL-01, 03, 04, 05; NFR-TPL-02). The directory
  ViewModel keeps only the loaded pages of the *current* query and never filters them. The current
  "load every page then filter by name or address on the device" path (`ILTemplesUseCaseImpl.loadTemples`
  + `ILTemplesViewModel.makeState`) is removed.
- **Client computes for display**: open status (BR-TPL-09) and distance (BR-TPL-07) are pure Domain
  functions (`ILTempleOpenStatus`, `ILTempleDistance`) with an injected clock / location, proven only
  by the product vectors (section "Product vectors"), not by restating the rules here.
- **Hidden actions** (BR-TPL-08): follow, offering and report are deleted from the ViewModel,
  ViewController, coordinator, UseCase and localization — not hidden behind a flag.

## Layers & components

| Layer | File | Responsibility | State |
|---|---|---|---|
| Domain / Entity | `Domain/Entities/ILTempleCatalogEntity.swift` | `ILTempleType`, `ILTempleRegion`, `ILTempleHeritageRank` (open enums), `ILTempleLocationEntity`, `ILTempleFacilitiesEntity`, `ILTempleSummaryEntity`, `ILTempleDetailEntity`. Foundation only. | built; **add** to location: `province`, `ward?`, `fullAddress`; **add** to detail: `holidayOperatingHours`, `sanghaBody`, `ILTempleContactsEntity` {hotline, fanpage, website, email}, `contentUpdatedMonth: (year, month)?` |
| Domain / Query | `Domain/Entities/ILTempleCatalogEntity.swift` (`ILTempleDirectoryQuery`) | `{ term: String?, region: ILTempleRegion? }` — the normalised request of criteria 6–8 (trimmed, cut to 100 characters, `nil` when empty). | planned |
| Domain / Repository protocol | `Domain/Repositories/ILTempleRepository.swift` | `loadTopTemples()`, `loadTemples(page:query:)` → `ILCatalogPageEntity` **with `total`**, `loadTempleDetail(id:)`. `query` defaults to "none" so `ILTempleFinderUseCase` keeps compiling unchanged. | built; **change** `loadTemples(page:)` signature + page entity gains `total` |
| Domain / Open status | `Domain/UseCases/Temple/ILTempleOpenStatus.swift` | Pure: `(now: Date, hours: ILTempleHours?, holidayHours: ILTempleHours?) → { status: open/closed/hidden, changeTime: HH:mm?, todayRow: normal/holiday/nil }`. Converts `now` to the Vietnam date and minute with a fixed `TimeZone(secondsFromGMT: 7 * 3600)` calendar, gets the lunar day of that date and of the next day from `ILLunarCalendar.solarToLunar(day:month:year:)`. Parses `"HH:MM - HH:MM"` (backend AC 46); `""` or unparseable → no hours. | planned (replaces `ILTempleViewModel.parseOperatingHours` / `isOpen`, which use the device time zone, ignore holiday hours and wrap past midnight) |
| Domain / Distance | `Domain/UseCases/Temple/ILTempleDistance.swift` | Pure: haversine km between two coordinates; `label(km: Double?) → String` (empty = hidden), formatting per BR-TPL-07 with a `vi_VN` comma decimal. | planned |
| Domain / Location protocol | `Domain/Repositories/ILUserLocationProviding.swift` | `currentCoordinate() async -> (lat, lng)?` — `nil` when access is not granted or no fix arrives within a short timeout. No storage. | planned |
| Domain / UseCase (directory) | `Domain/UseCases/Temples/ILTemplesUseCase.swift` | `loadPage(_ page: Int, query: ILTempleDirectoryQuery) → ILCatalogPageEntity` — one page, no loop, no de-dup across pages (the ViewModel appends). | built as "load all"; **rewrite** |
| Domain / UseCase (page) | `Domain/UseCases/Temple/ILTempleUseCase.swift` | `loadTemple(id:)`. | built; **remove** `toggleFollow` stub |
| Data / DTO | `Data/DTOs/ILTempleDTO.swift`, `ILCatalogListDTO.swift` | Summary, detail, location, amenities DTOs. New fields are **optional** so a detail cached before the contract change still decodes. | built; **add** `location.province`, `ward`, `full_address`; detail `holiday_operating_hours`, `sangha_body`, `contacts`, `content_updated_month` |
| Data / Mapper | `Data/DTOs/Mappers/ILTempleMapper.swift` | DTO → Entity; trims text; `nil` → empty; `content_updated_month` `YYYY-MM` → (year, month) or `nil`. | built; **extend** |
| Data / Endpoint | `Data/DataSources/Remote/TemplesPageEndpoint.swift` | `GET /v1/temples?page=N[&q=][&region=]` — sends `q` / `region` only when set (criterion 7–8). | built (page only); **add** `q`, `region` |
| Data / Endpoints | `TopTemplesEndpoint`, `TempleDetailEndpoint` | `GET /v1/temples/top`, `GET /v1/temples/{id}`. | built |
| Data / Repository | `Data/Repositories/ILTempleRepositoryImpl.swift` | See "Caching" below. Maps every failure to `ILCatalogError` (`.notFound`, `.offline`, …). | built; **change** list policy |
| Data / Local | `Data/DataSources/Local/ILTempleLocalDataSource.swift`, `ILCatalogCache*`, Core Data `CachedTemple` / `CatalogListState` | Cached top list, unfiltered directory pages, temple details. | built; **change** only for the new fields (stored in the cached detail JSON) and the page-size change (reset of the cached layout, already done when `total`/`page_size` differ) |
| Data / Location | `Data/DataSources/Device/ILUserLocationProvider.swift` | `CLLocationManager` wrapper implementing `ILUserLocationProviding`; asks "When In Use" at the moment decided by the location ⚠️ (requirements criterion 31); one-shot reduced-accuracy fix is enough; never persists or logs the coordinate. `Info.plist` `NSLocationWhenInUseUsageDescription`. | planned — blocked on ⚠️ |
| Presentation / Directory | `Presentation/Scenes/Temples/ILTemplesViewModel.swift`, `ILTemplesStateModel.swift`, `ILTemplesViewController.swift`, `Views/ILTemplesRowCell.swift`, `ILTemplesCoordinator.swift` | VM: query state (`term`, `region`), debounced term (400 ms), page cursor, `hasMore`, in-flight guard, append-only rows de-duplicated by `id`, subtitle from `total`, footer state (loading / retry). VC: `ILStickyHeaderBand` + `ILNavBar` + `ILSearchInputView` + region `ILChip`s (reused `ILTempleFinderRegionFilter`), table under the band, load-more trigger near the end. | VC / coordinator / chips built; **rewrite** VM; row cell **change** (criterion 14); placeholder copy ⚠️ |
| Presentation / Temple page | `Presentation/Scenes/Temple/ILTempleViewModel.swift`, `ILTempleStateModel.swift`, `ILTempleViewController.swift`, `Views/ILTempleHeroView.swift`, `Views/ILTempleStatusCardView.swift`, `Views/ILTempleSkeletonView.swift` | VM: load → state mapping (sections of criterion 17), open status via `ILTempleOpenStatus` with an injected `now`, distance via `ILTempleDistance` + `ILUserLocationProviding`, Maps / contact URLs, not-found vs error. VC: sections, error/offline/not-found states. | built; **change**: remove follow / offer / report / events tap / session tap; status hidden without hours; fill new fields; not-found state; hero image placeholder; recompute on foreground |
| Presentation / Coordinator | `Presentation/Scenes/Temple/ILTempleCoordinator.swift` | `.back` → pop + `finish()`; `.openURL` → `UIApplication.shared.open`. | built; **remove** `.offer`, `.events`, `.session` cases |
| Presentation / Home block | `Presentation/Scenes/Home/ILHomeViewModel.swift`, `Views/ILHomeTempleCarouselView.swift` | Featured cards, "Xem tất cả", empty / "updating" state. | built; card fields **change** (criterion 14) |
| Presentation / Labels | `Presentation/Common/Formatting/ILTempleCatalogLabels.swift` | Rank / sect / region / type labels shared by cards and the temple page. | built; **add** `typeLabel`; place line from `ward` + `province` instead of parsing `address` |
| Localization | `Resources/Localization/vi.json` (+ `en`) | `temple.*`, `temples.*`, `home.temple.*`. | **remove** `temple.follow`, `temple.following`, `temple.offer`, `temple.footer.reportIssue`; **change** `temple.events.empty` to the FR-TPL-009 text; `temples.search.placeholder` (⚠️) |
| DI | `App/DIContainer.swift` | `makeTemple*`, `makeTemples*`, location provider. | built; **add** location provider |
| Product vectors | `InnerLampTests/ILTempleProductVectorTests.swift` + `InnerLampTests/ProductVectors/temple/*.json` + `Scripts/sync-product-vectors.sh` | Runs every case of `temple-distance.json` and `temple-open-status.json`. | planned |

## Navigation flow

```
ILHomeCoordinator
  ├─ (.openTemple(id)) → showTemple(id) → ILTempleCoordinator (leaf)
  └─ (.openTemples)    → showTemples()  → ILTemplesCoordinator
                            push ILTemplesViewController
                            (.openTemple(id)) → ILTempleCoordinator (leaf)
                            (.back) → pop + finish()

ILSanghaCoordinator / ILTempleFinderCoordinator / family-tree coordinators
  └─ showTemple(id) → ILTempleCoordinator (leaf)

ILTempleCoordinator
  push ILTempleViewController
  (.back) → pop + finish()
  (.openURL(url)) → UIApplication.shared.open(url)   [Google Maps / Apple Maps / tel: / https / mailto:]
```

## Step-by-step Flow — Directory (search, filter, pages)

```
Step 1 — First page (this feature)
- Trigger: directory screen `viewDidLoad`, or "Thử lại" on the full error state
- Pre-condition: query = { term: nil, region: nil } (or the current query on retry)
- API: GET /v1/temples?page=1 [&q=<term>] [&region=<north|central|south>]
  ⚠️ Not confirmed: `q` / `region` and page size 12 are not in openapi.yaml @ a8a016b (backend v2.0 Phase 11–13).
    - Success → rows = items (order kept), subtitle = total, hasMore = page < total_pages && items non-empty; empty items → "Không tìm thấy chùa" (criterion 10)
    - Failure (offline / unreachable, unfiltered query, cached page 1) → cached rows + count (criterion 37)
    - Failure (otherwise) → full error state + "Thử lại" (criteria 12, 38)

Step 2 — Next page (this feature)
- Trigger: the table scrolls within the last few rows, hasMore == true, no request in flight
- Pre-condition: same query as Step 1's response
- API: GET /v1/temples?page=<last + 1> with the same q / region
    - Success → append rows whose id is not shown yet; update hasMore (stop on empty page or last page)
    - Failure → keep rows; list footer shows "Thử lại", which repeats this step

Step 3 — Query change (this feature)
- Trigger: search text changes (debounced 400 ms after the last keystroke; NFR-TPL-01) or a region chip
  is selected (immediately); a term equal to the current one after trimming / cutting is ignored
- Pre-condition: none
- Effect: cancel the in-flight task, reset rows / cursor, then run Step 1 with the new query; a response
  whose query differs from the current one is dropped (criterion 9)
```

## Step-by-step Flow — Temple page

```
Step 1 — Load the profile (this feature)
- Trigger: temple page `viewDidLoad`, or "Thử lại"
- API: GET /v1/temples/{id}
  ⚠️ Not confirmed: `holiday_operating_hours`, `sangha_body`, `contacts`, `content_updated_month` are not in openapi.yaml @ a8a016b — decoded as optional; absent → missing values (BR-TPL-06).
    - Success → map to ILTempleStateModel; store the copy; go to Step 2 (status) and Step 3 (distance) in parallel
    - Failure (404 TEMPLE_NOT_FOUND) → drop the cached copy; "not found" state with back (criterion 16)
    - Failure (offline / unreachable, cached copy) → show the copy, then Steps 2–3
    - Failure (otherwise) → error state (offline / generic) + "Thử lại"

Step 2 — Open status (this feature, no network)
- Trigger: Step 1 success; page re-appears; app enters foreground
- Effect: ILTempleOpenStatus(now(), hours, holidayHours) → status line + "Hôm nay" row; hidden without hours

Step 3 — Distance (this feature, device location — no network)
- Trigger: Step 1 success
- Pre-condition: location access granted (when the app asks is ⚠️, requirements criterion 31)
- Effect: ILUserLocationProviding.currentCoordinate() → ILTempleDistance → label; nil / denied → line hidden
```

The Home block makes a single call (`GET /v1/temples/top`, network-first, cached copy on failure, empty
state otherwise) and needs no step list.

## Caching

- `top` and temple detail: **network-first**, cached copy only when the server cannot be reached; a
  `404` evicts the cached detail (unchanged).
- Directory pages: **changed from local-first to network-first.** Only unfiltered pages
  (`q == nil && region == nil`) are stored and used as an offline fallback; search / region pages are
  never stored (criterion 38). Reason: a local-first page hides a changed `total` and new temples until
  the cache resets, and the server now owns search / filter, so a cache cannot answer them.
- The page-size change (20 → 12) changes `page_size` / `total_pages` of the response; the existing
  "reset the cached layout when the server's paging differs" rule covers it.
- `ILTempleFinderUseCase` (practice-temple picker, out of scope) keeps calling `loadTemples(page:)`
  with no query; under network-first it gets fresh pages and the same offline fallback.

## Product vectors

- `Scripts/sync-product-vectors.sh` (shared with `Docs/Specs/Memorial/`, created by whichever feature
  lands first) copies `../innerlamp-be/docs/product/temple/rules/{temple-distance,temple-open-status}.json`
  into `InnerLampTests/ProductVectors/temple/`, recording the backend commit sha and file hashes in a
  `SOURCE` file. The copies are never hand-edited.
- `ILTempleProductVectorTests` runs every case: distance cases through `ILTempleDistance.label(km:)`;
  open-status cases through `ILTempleOpenStatus` with `now_utc` as the injected instant (the test host's
  time zone must not matter — run it once under a non-UTC+7 zone), comparing `status`, the label built
  from `changeTime` with the `temple.status.*` strings, and `today_row`. `vietnam_lunar_day_today` is
  asserted against `ILLunarCalendar` as a cross-check only.
- `temple-order.json` and `temple-search-match.json` are backend-only (product §4.1): the app neither
  sorts nor matches.

## Deliberately stubbed for now

- The events section always shows its empty state; no request is made (FR-TPL-009 — events come from
  `sangha`; the backend's authenticated `GET /v1/temples/{id}/events` belongs to that feature).
- The location section map is a static placeholder.

## Design reference

Prototype screens `temple` and `temples` and the home block "Chùa Việt Nam" (product §1.5). Per-screen
implementation notes: `InnerLamp/Presentation/Scenes/Temple/README.md`,
`InnerLamp/Presentation/Scenes/Temples/README.md`.

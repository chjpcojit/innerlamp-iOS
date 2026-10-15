# Design — Deity

Version: 1.1
Last updated: 2026-10-15
Status: in-progress — carousels, catalogue screen, deity page, top/page/detail endpoints and Core Data cache built against the old contract; planned: server paging + `type` filter, vía (a deity's feast day, kept on a lunar date) from the backend with device-date countdown, related sutras endpoint, iconography + name block, single action row, prototype empty state, network-first cache, removal of the bundled catalogue

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. Four entry surfaces share one Data layer
(`ILDeityCatalogRepository`):

- **Home block** "Thư viện Phật & Bồ Tát" (Library of Buddhas & Bodhisattvas) — part of `Presentation/Scenes/Home/` (`ILHomeDeityCarouselView`),
  fed by `ILHomeUseCase.loadTopDeities()`.
- **Library block** "Chư Phật & Bồ Tát" (Buddhas & Bodhisattvas) + tile "Phật & Bồ Tát" (Buddhas & Bodhisattvas) — part of `Presentation/Scenes/Library/`,
  same carousel view, fed by `ILLibraryUseCase.loadTopDeities()`.
- **Catalogue** — `Presentation/Scenes/Deities/` (`ILDeitiesCoordinator`, child of `ILHomeCoordinator` /
  `ILLibraryCoordinator`). Code folder name stays `Deities` (product §1.5).
- **Deity page** — `Presentation/Scenes/Deity/` (`ILDeityCoordinator`, leaf), pushed by Home, Library and
  the catalogue with a server deity `id`.

How iOS meets the product constraints (see `requirements.md` "Constraints"):

- **Server does order / filter / paging** (BR-DTY-02, 03; FR-DTY-003; NFR-DTY-01). The catalogue ViewModel
  keeps only the loaded pages of the *current* chip and never filters them. The current "load every page
  (cap 50), fall back to `top`, then filter by kind on the device" path (`ILDeitiesUseCaseImpl.loadDeities`
  / `deities(in:kind:)`) is removed.
- **Server gives vía days and the next vía** (BR-DTY-05, 06). The on-device lunar scan
  (`ILDeityUseCaseImpl.upcomingMemorialDay` / `nextOccurrence`, 400-day window, UTC+7 calendar) and the
  "Đản / Vía" (birth anniversary / feast day) name match (`ILDeityEntity.primaryMemorialDay`, `ILHomeUseCaseImpl.primaryMemorialDay`) are
  deleted. The app only computes the countdown with `ILCalendarRules.countdown(today:solarDate:calendar:)`
  (planned in `Docs/Specs/Calendar/design.md`; created by whichever feature lands first) using the
  **device** calendar and date (BR-CAL-13), not a fixed UTC+7 calendar.
- **"Today" sent to the server**: every deity request carries `date=YYYY-MM-DD` = the device's current
  date (backend deity requirements v3.0 AC 25), so the server's next vía matches the device countdown.
- **Related sutras from the sutra library** (FR-DTY-007): `relatedSutras(for:)`, the `librarySutraIDs`
  table and `ILDeityEntity.canonicalSources` (comma split) are deleted; `canonical_source` is shown as a
  plain line (FR-DTY-005).
- **Hidden actions** (BR-DTY-08): "· Báo thông tin sai" (· Report incorrect information) is removed from `deity.footnote`, not hidden.

## Layers & components

| Layer | File | Responsibility | State |
|---|---|---|---|
| Domain / Entity (detail) | `Domain/Entities/ILDeityEntity.swift` | `ILDeityKind` (buddha, bodhisattva, deva), `ILDeityIconographyEntity`, `ILDeityMantraEntity`, `ILDeityEntity` (all `DeityDetail` fields, `imageURL`). Foundation only. | built; **add** `nextVia: ILDeityViaEntity?`, `viaEvents: [ILDeityViaEventEntity]`; **remove** `memorialDays` / `ILDeityMemorialDayEntity`, `ILDeityUpcomingMemorialDayEntity`, `ILDeityRelatedSutraEntity`, `primaryMemorialDay`, `canonicalSources` |
| Domain / Entity (vía) | `Domain/Entities/ILDeityEntity.swift` | `ILDeityViaEntity` {eventCode, name, solarDate (y/m/d, no time zone), lunarDay, lunarMonth, lunarYear, isLeapMonth}; `ILDeityViaEventEntity` {eventCode, name, next: ILDeityViaEntity?}. Shapes per backend AC 29. | planned — blocked on contract |
| Domain / Entity (summary) | `Domain/Entities/ILDeitySummaryEntity.swift` | Card row of `top` / list. | built; **add** `nextVia: ILDeityViaEntity?` |
| Domain / Entity (list) | `Domain/Entities/ILDeitiesEntity.swift` | Today: whole catalogue aggregate. | built; **remove** (the ViewModel holds pages) |
| Domain / Entity (page) | `Domain/Entities/ILCatalogPageEntity.swift` | `items`, `page`, `hasMore`. Shared with Temple / Sutras. | built; **add** `total` (shared change, also asked by `Docs/Specs/Temple/` — whichever lands first) |
| Domain / Entity (related sutra) | `Domain/Entities/ILDeityRelatedSutraEntity.swift` (new) | `{ sutraID, titleVi }` — only what the section shows. | planned |
| Domain / Repository protocol | `Domain/Repositories/ILDeityCatalogRepository.swift` | `loadTopDeities(today:)`, `loadDeities(page:kind:today:)` → `ILCatalogPageEntity` with `total`, `loadDeityDetail(id:today:)`, `loadRelatedSutras(deityID:)` (page 1). `today` is a `DateComponents`-style y/m/d value. Every failure is an `ILCatalogError`. | built; **change** signatures, **add** related sutras |
| Domain / Repository (dead) | `Domain/Repositories/ILDeityRepository.swift`, `ILDeityError` | Bundled-catalogue reader (lunar-date / search queries). No production caller; `phat_botat.json` is not in the bundle. | built; **remove** |
| Domain / UseCase (page) | `Domain/UseCases/Deity/ILDeityUseCase.swift` | `loadDeity(id:)`, `loadRelatedSutras(id:)`; injects `today: () -> Date` + device `Calendar` to build the `date` value and the countdown. | built; **remove** `getAllDeities()` + the 18-item static catalogue, `upcomingMemorialDay`, `relatedSutras(for:)`, the UTC+7 calendar |
| Domain / UseCase (catalogue) | `Domain/UseCases/Deities/ILDeitiesUseCase.swift` | `loadPage(_ page: Int, kind: ILDeityKind?) → ILCatalogPageEntity` — one page, no loop, no `top` fallback, no device filter. `kind` is `nil`, `.buddha` or `.bodhisattva` only. | built as "load all + filter"; **rewrite** |
| Domain / UseCase (blocks) | `Domain/UseCases/Home/ILHomeUseCase.swift`, `Domain/UseCases/Library/ILLibraryUseCase.swift` | `loadTopDeities()` → `ILHomeDeityEntity` via `ILHomeUseCaseImpl.makeDeity(from:)`. | built; **change** `makeDeity` to carry `nextVia`; **remove** `primaryMemorialDay` |
| Domain / Countdown | `Domain/UseCases/Calendar/ILCalendarRules.swift` (owned by `Docs/Specs/Calendar/`) | `countdown(today:solarDate:calendar:)` → `.today` / `.tomorrow` / `.daysLeft(n)` / `.passed(n)` (BR-CAL-13). | planned (Calendar) — reused, not duplicated |
| Data / DTO | `Data/DTOs/ILDeitySummaryDTO.swift`, `Data/DTOs/ILDeityDTO.swift` | Summary + detail wire shapes. New fields (`next_via`, `via_events`) are **optional** so an old cached copy and the current server still decode. `lunar_memorial_days` is no longer read. | built; **add** `ILDeityViaDTO`, `ILDeityViaEventDTO`; **remove** `lunar_memorial_days` decoding and the `phat_botat.json` doc comment |
| Data / DTO (sutras) | `Data/DTOs/ILSutraDTO.swift` (reuse) or `ILDeitySutraDTO` | Reads only `id` and `titles.vi` of each `SutraSummary` item of `GET /v1/deities/{id}/sutras`. | planned |
| Data / Mapper | `Data/DTOs/Mappers/ILDeityMapper.swift` | DTO → Entity; `type` → `ILDeityKind`; `next_via` / `via_events` → vía entities; `YYYY-MM-DD` → y/m/d (invalid → `nil`); trims text. | built; **extend** |
| Data / Endpoints | `Data/DataSources/Remote/TopDeitiesEndpoint.swift`, `DeitiesPageEndpoint.swift`, `DeityDetailEndpoint.swift` | `GET /v1/deities/top[?date=]`, `GET /v1/deities?page=N[&type=][&date=]`, `GET /v1/deities/{id}[?date=]`. `type` only when a chip other than "Tất cả" (All) is selected. | built (no `type` / `date`); **add** query items |
| Data / Endpoint (sutras) | `Data/DataSources/Remote/DeitySutrasEndpoint.swift` (new) | `GET /v1/deities/{id}/sutras?page=1` (no `role`). | planned |
| Data / Repository | `Data/Repositories/ILDeityCatalogRepositoryImpl.swift` | See "Caching" below. | built; **change** list policy to network-first; **add** sutras call; 404 evicts the cached detail |
| Data / Local | `Data/DataSources/Local/ILDeityCatalogLocalDataSource.swift`, Core Data `ILCachedDeityMO` + list state | Cached top list, unfiltered pages, details. | built; **change**: store `next_via` / `via_events` (cached detail JSON), store `image_url` (TD-Deity-001), store the request date; reset cached pages when `page_size` / `total` differ |
| Data / Local (dead) | `Data/DataSources/Local/ILDeityLocalDataSource.swift`, `ILDeityMO.swift`, `Data/Repositories/ILDeityRepositoryImpl.swift` | Seeds Core Data from the missing `phat_botat.json`. | built; **remove** (with its Core Data entity, if no other user — check the model) |
| Presentation / Catalogue | `Presentation/Scenes/Deities/ILDeitiesViewModel.swift`, `ILDeitiesStateModel.swift`, `ILDeitiesViewController.swift`, `Views/ILDeitiesGridView.swift`, `ILDeitiesCardView.swift`, `ILDeitiesSkeletonView.swift`, `ILDeitiesCoordinator.swift` | VM: chip state, cancel in-flight + drop stale responses, page cursor + `hasMore`, in-flight guard, append-only cards de-duplicated by `id`, subtitle from `total`, footer state (loading / retry), prototype empty state with "Thử lại" (Retry) + "Xem lịch lễ vía" (See the feast-day calendar). VC: existing sticky header band + chips; load-more trigger near the end of the grid; incremental append (AGENTS.md §4.6). Coordinator: **add** `.openFestivals`. | VC / grid / skeleton / coordinator built; **rewrite** VM; **change** card vía line, empty / error state |
| Presentation / Deity page | `Presentation/Scenes/Deity/ILDeityViewModel.swift`, `ILDeityStateModel.swift`, `ILDeityViewController.swift`, `Views/ILDeityHeroView.swift`, `ILDeityMemorialDayCardView.swift`, `ILDeityVowRowView.swift`, `ILDeityMantraCardView.swift` | VM: load detail + related sutras in parallel; state mapping in FR-DTY-005 order; vía card from `nextVia` + countdown; vía list from `viaEvents`; not-found vs error; reload on re-appear with a new device date. VC: name block (honorific, Sanskrit, Chinese as text), canonical source line, "Hình tượng" (Iconography) section (new `Views/ILDeityIconographyView.swift`), one chant + one share action under the mantra cards, sutra rows from the endpoint, not-found state. | built; **change** (see Phase 4) |
| Presentation / Coordinator | `Presentation/Scenes/Deity/ILDeityCoordinator.swift` | `.back`, `.openFestivals` → Festivals, `.openMala(text)` → Mala, `.share(text)` → `UIActivityViewController`, `.openSutra(id)` → SutraDetail. | built; unchanged |
| Presentation / Blocks | `Presentation/Scenes/Home/ILHomeViewModel.swift`, `ILHomeStateModel.swift` (`ILHomeDeityModel`), `Views/ILHomeDeityCarouselView.swift`; `Presentation/Scenes/Library/ILLibraryViewModel.swift`, `ILLibraryStateModel.swift`, `ILLibraryViewController.swift` | Featured cards, "Xem tất cả" (See all), tile, loading skeleton, empty state. | built; **change** vía line from `nextVia`, kind label, block empty state (⚠️) |
| Presentation / Labels | `ILDeitiesViewModel.kindLabel(for:)` | "Phật" (Buddha) / "Bồ Tát" (Bodhisattva) / "Chư Thiên" (devas) — the one source used by cards, the page and the blocks. | built; **change** `deva` copy |
| Localization | `Resources/Localization/vi.json` | `deity.*`, `deities.*`, `home.deity.*`, `library.deity.*`. | **change** `deity.kind.deva` → "Chư Thiên", `deity.footnote` (drop "· Báo thông tin sai"), month format to "THÁNG %@" (MONTH %@) with Giêng (first lunar month) / Chạp (twelfth lunar month); **add** empty-state title / hint / actions (`deities.empty.*`), not-found, iconography labels (⚠️), leap marker, vía list; **remove** `deities.memorialUpdating`, `home.deity.memorialUpdating`, `deity.sutra.pending` / `available` / `open`, `deities.updating`, `deities.error.*` if unused |
| DI | `App/DIContainer.swift` | `makeDeity*`, `makeDeities*`, `makeDeityCatalogRepository`. | built; **remove** `deityLocalDataSource`, `makeDeityRepository` |
| Tests | `InnerLampTests/ILDeityViewModelTests.swift`, `ILDeitiesViewModelTests.swift`, `ILDeityCatalogRepositoryTests.swift`, `ILHomeViewModelTests.swift`, `ILLibraryViewModelTests.swift`, `ILDeityRepositoryTests.swift` | ViewModel / UseCase / repository tests with stub repositories. | built (old behavior); **rewrite** per phase; **remove** `ILDeityRepositoryTests` with the dead repository |
| Product vectors | `InnerLampTests/ILDeityProductVectorTests.swift` + `InnerLampTests/ProductVectors/deity/deity-next-via.json` + `Scripts/sync-product-vectors.sh` | Countdown part of BR-DTY-06 (see "Product vectors"). | planned |

## Navigation flow

```
ILHomeCoordinator / ILLibraryCoordinator
  ├─ (.openDeity(id)) → showDeity(id)   → ILDeityCoordinator (leaf)
  └─ (.openDeities)   → showDeities()   → ILDeitiesCoordinator
                          push ILDeitiesViewController
                          (.openDeity(id))  → ILDeityCoordinator (leaf)
                          (.openFestivals)  → Festivals ("Xem lịch lễ vía", new)
                          (.back) → pop + finish()

ILDeityCoordinator
  push ILDeityViewController
  (.back)            → pop + finish()
  (.openFestivals)   → Festivals ("Lịch lễ")
  (.openMala(text))  → Mala with the short mantra, count 0
  (.share(text))     → UIActivityViewController
  (.openSutra(id))   → ILSutraDetailCoordinator(sutraID:)
```

## Step-by-step Flow — Catalogue (filter, pages)

```
Step 1 — First page (this feature)
- Trigger: catalogue `viewDidLoad`, a chip change, or "Thử lại" on the empty state
- Pre-condition: kind = nil ("Tất cả"), .buddha or .bodhisattva; today = device date
- API: GET /v1/deities?page=1 [&type=BUDDHA|BODHISATTVA] &date=<today>
  Page size and `type` exist at a8a016b (size 20 there); `date` and `next_via` per backend deity
  requirements v3.0 AC 2, 5, 24–26 (contract not yet in openapi.yaml). Page size is read from the
  response, never assumed.
    - Success → cards = items (order kept), subtitle N = total, hasMore = page < total_pages && items non-empty;
      no item → empty state (criterion 9)
    - Failure (offline / unreachable, kind == nil, cached page 1) → cached cards + count (criterion 30)
    - Failure (otherwise) → empty state "Chưa có thông tin chư Phật" + "Thử lại" + "Xem lịch lễ vía" (criteria 9, 31)

Step 2 — Next page (this feature)
- Trigger: the grid scrolls within the last row or two, hasMore == true, no request in flight
- Pre-condition: same kind as Step 1's response
- API: GET /v1/deities?page=<last + 1> with the same type / date
    - Success → append cards whose id is not shown yet; update hasMore (stop on empty or last page)
    - Failure → keep cards; footer "Thử lại" repeats this step (criterion 10)

Step 3 — Chip change (this feature)
- Trigger: the user selects a chip other than the selected one
- Effect: cancel the in-flight task, reset cards / cursor, run Step 1 with the new kind; a response whose
  kind differs from the current one is dropped (criterion 8)
```

## Step-by-step Flow — Deity page

```
Step 1 — Load the profile (this feature)
- Trigger: deity page `viewDidLoad`, "Thử lại", or re-appear on a later device date (criterion 24)
- Pre-condition: id from a card; today = device date
- API: GET /v1/deities/{id}?date=<today>
  `next_via` / `via_events` / `date` per backend deity requirements v3.0 AC 8, 12, 24–30 (contract not
  yet in openapi.yaml); decoded as optional — absent → no vía card (as today's server).
    - Success → map to ILDeityStateModel (FR-DTY-005 order); store the copy; vía card countdown =
      ILCalendarRules.countdown(today, nextVia.solarDate, device calendar)
    - Failure (404 DEITY_NOT_FOUND) → drop the cached copy; "not found" state with back (criterion 13)
    - Failure (offline / unreachable, cached copy) → show the copy (stale vía: ⚠️ criterion 32)
    - Failure (otherwise) → error state (offline / generic) + "Thử lại"

Step 2 — Related sutras (this feature; runs in parallel with Step 1, shown after Step 1 succeeds)
- Trigger: same as Step 1
- API: GET /v1/deities/{id}/sutras?page=1 (no role) — exists at a8a016b
    - Success → "Kinh liên quan" rows (titles.vi, id) in the order received; no item → no section
    - Failure (any) → no section; Step 1's result is unaffected (criterion 27, ⚠️)

Step 3 — Open a related sutra (SutraDetail feature, out of this feature's scope)
- Trigger: tap on a row → .openSutra(id) → ILSutraDetailCoordinator, which calls GET /v1/sutras/{id}
  (see Docs/Specs/SutraDetail/design.md)
```

The Home and Library blocks each make a single call (`GET /v1/deities/top?date=`, network-first, cached
copy on failure, block empty state otherwise) and need no step list.

## Caching

- `top` and deity detail: **network-first**, cached copy only when the server cannot be reached; a `404`
  evicts the cached detail (new — today a 404 is rethrown but the copy stays).
- Catalogue pages: **changed from local-first to network-first.** Today `loadDeities(page:)` returns a
  cached page whenever one exists, so cached pages never expire and a changed catalogue, page size or
  next vía is never seen. Only unfiltered pages (`type == nil`) are stored and used as an offline
  fallback; filtered pages are never stored (criterion 31).
- The page-size change (20 → 12) changes `page_size` / `total_pages`; the cached layout is reset when they
  differ from the stored ones.
- Stored copies keep the `date` they were requested with. A copy is shown only offline (criterion 32);
  what it does with a next vía before today is ⚠️ (product).

## Product vectors

- `rules/deity-order.json` (BR-DTY-02) is backend-only: the app neither sorts nor filters.
- `rules/deity-next-via.json` (BR-DTY-06): the choice of the next vía is the backend's (backend AC 24), so
  iOS does not re-implement it. `ILDeityProductVectorTests` runs every case for the part iOS computes:
  for each case with a non-null `expected.next_via`, `ILCalendarRules.countdown(today:solarDate:)` with
  `input.today` and `expected.next_via.solar_date` must give `expected.days` and the label
  (`today` → "Hôm nay" (Today), `tomorrow` → "Ngày mai" (Tomorrow), `days_left` → "Còn n ngày" (n days left)); the null case asserts the
  mapper / ViewModel shows no vía card for `next_via: null`.
- `Scripts/sync-product-vectors.sh` (shared with Memorial / Temple / Calendar, created by whichever lands
  first) copies `../innerlamp-be/docs/product/deity/rules/deity-next-via.json` into
  `InnerLampTests/ProductVectors/deity/` with a `SOURCE` file (backend commit sha + hash); never
  hand-edited.

## Deliberately stubbed for now

- Until backend deity v3.0 ships, the summaries and the detail carry no `next_via` / `via_events`: the
  card shows no vía line and the page no vía card (the decoded fields are `nil`), instead of the
  on-device scan. This means shipping Phase 4's vía removal before the backend would hide vía days that
  today's app shows — keep Phase 2–4 vía tasks in one release with the backend change.

## Design reference

Prototype screens `buddhas`, `buddhasEmpty`, `buddha`, the home section "Thư viện Phật & Bồ Tát" and the
library block / tile (product §1.5). Per-screen implementation notes:
`InnerLamp/Presentation/Scenes/Deity/README.md`, `InnerLamp/Presentation/Scenes/Deities/README.md`.

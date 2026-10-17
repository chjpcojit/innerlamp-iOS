# Design — Calendar

Version: 1.2
Last updated: 2026-10-17
Status: in-progress — festival calendar, event detail and Home's events block built against `GET /v1/calendar/events` (signed-in, network only); planned: server-only Rằm / Mùng Một, filters by group, 2100 limit, retry and device copy, hidden empty sections, home-block window and tiers, shared rule functions + product vectors; public route, `is_major` and `recurrence` wait on backend v3.0

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. Three surfaces read one year-based data layer:

- **Festival calendar** — scene `Festivals` (`ILFestivalsCoordinator`), pushed as a child coordinator by
  `ILHomeCoordinator` ("Tất cả", "+N sự kiện khác"), `ILSanghaCoordinator` ("Lịch lễ") and
  `ILDeityCoordinator`. Not cross-section: each parent pushes it on its own navigation stack.
- **Event detail** — scene `FestivalDetail` (`ILFestivalDetailCoordinator`), a leaf pushed by
  `ILFestivalsCoordinator` and `ILHomeCoordinator`.
- **Home's events block** — part of the `Home` scene (`ILHomeEventsCarouselView`); `Docs/Specs/Home/`
  owns the rest of Home.

Scene folder names stay `Festivals` / `FestivalDetail` (product §1.5 maps them; ⚠️ default in
`requirements.md` Pending). How iOS meets the product constraints (see `requirements.md`):

- **The server computes every date** (BR-CAL-01…07, BR-CAL-05): the app keeps no event catalogue and
  calls no lunar conversion for this feature. The local day loop that adds Rằm / Mùng Một is removed;
  the unused Core Data catalogue (`ILBuddhistEvent*`) is deleted.
- **The app computes three things, in one place**: countdown (BR-CAL-13), order where it merges or
  tiers occurrences (BR-CAL-12) and the home block (BR-CAL-15) live in `ILCalendarRules`, a pure Domain
  type. Its correctness is proven only by the product vectors (row "Product vectors"), not by restating
  the rules here.
- **One year = one request**, shared: one repository instance keeps loaded years in memory for the app
  session and a device copy per year on disk (FR-CAL-007). The detail reuses the year the list or Home
  already loaded (product Appendix A: no separate detail capability).
- **Public route** (FR-CAL-001): once the contract drops bearer auth, the endpoint stops attaching the
  token (`requiresAuth = false`) and sends no `X-API-Key`.

## Layers & components

| Layer | File | Responsibility | State |
|---|---|---|---|
| Domain / Entity | `Domain/Entities/ILCalendarEventEntity.swift` | `ILCalendarEventsEntity` (year, groups, events, occurrences), `ILCalendarGroupEntity`, `ILCalendarEventEntity` (code, name, short/long description, guidance, `imageURL?`, `groupCodes`, `isPublicHoliday`), `ILCalendarOccurrenceEntity` (eventCode, solarDate, lunar day/month/leap). Foundation only. | built; **add** `isMajor: Bool`, `sortOrder: Int?`, `recurrence: ILCalendarRecurrenceKind` (`solar` / `lunar` / `lunarMonthly` / `lunarLastDay` / `solarTerm` / `unknown`) — waits on backend v3.0 |
| Domain / Rules (planned) | `Domain/UseCases/Calendar/ILCalendarRules.swift` | Pure, no I/O, no clock: `countdown(today:solarDate:calendar:)` → `ILCalendarCountdown` (`.today`, `.tomorrow`, `.daysLeft(n)`, `.passed(n)`) (BR-CAL-13); `ordered(_:)` by solar date, `sortOrder`, code (BR-CAL-12); `homeBlockMonth(_:)` → shown occurrences + more count (BR-CAL-15: group code `buddhist`, tier 1 `isMajor`, tier 2 other, tier 3 `recurrence == .lunarMonthly`, max 3). | planned — replaces the three private `countdownText` / `daysBetween` copies and the Home `prefix(3)` |
| Domain / Repository protocol | `Domain/Repositories/ILCalendarEventRepository.swift` | Today `loadEvents(year:)`, network only. Planned: `cachedEvents(year:) async -> ILCalendarEventsEntity?` (memory, then device copy) and `loadEvents(year:) async throws -> ILCalendarYearResult` (`entity`, `isStale` — `true` when the server failed and the device copy was returned). | built; **change** |
| Domain / Error | `Domain/Repositories/ILCatalogError.swift` | Shared `.offline` / `.loadFailed` / `.notFound`; 429 `RATE_LIMITED` maps to `.rateLimited(retryAfterSeconds:)`. | built, reused |
| Data / Remote | `Data/DataSources/Remote/CalendarEventsEndpoint.swift` | `GET /v1/calendar/events?year=` (always sends `year`). | built; `requiresAuth = false` (openapi 2.2.0); never sends `X-API-Key` |
| Data / DTO + Mapper | `Data/DTOs/ILCalendarEventsDTO.swift`, `Data/DTOs/Mappers/ILCalendarEventMapper.swift` | Wire ↔ entity; drops occurrences with an unknown event or unparsable date; `solar_date` → start of that day in the device calendar. | built; `is_major`, `sort_order`, `recurrence` are required fields (openapi 2.2.0; an unknown `recurrence` value → `.other`); **still to do:** DTOs become `Codable` so the device copy can store them |
| Data / Local (planned) | `Data/DataSources/Local/ILCalendarEventLocalDataSource.swift` | Device copy: `read(year:)`, `write(_:year:)`, `deleteYears(before:)` — one JSON file per year (`ILCalendarEventsDTO` + `savedAt`) under `Application Support/CalendarEvents/<year>.json`, written atomically, excluded from nothing (public content, no personal data). Not cleared on sign-out. | planned (⚠️ default, `requirements.md` criterion 19) |
| Data / Repository impl | `Data/Repositories/ILCalendarEventRepositoryImpl.swift` | Today: one network call, every failure → `ILCatalogError`. Planned: an `actor` holding loaded years for the session; `loadEvents` = memory hit → return it; else server → write copy (best effort) → return fresh; server failure → device copy with `isStale = true`, or throw. See "Step-by-step Flow — Load one year". | built; **change** |
| DI | `App/DIContainer.swift` | `makeCalendarEventRepository()` builds a new instance per call today. | built; **change** to one `lazy var calendarEventRepository` so Home, the calendar and the detail share the memory copy; add the local data source |
| Festivals / Entity | `Domain/Entities/ILFestivalsEntity.swift` | `ILFestivalDayEntity` (id, date, title, kind, daysUntil, lunar day/month/leap, `eventCode?`), `ILFestivalMonthEntity`, `ILFestivalsEntity`. | built; **change**: day gains `groupCodes`, `isMajor`, non-optional `eventCode`, `countdown: ILCalendarCountdown` (replaces `daysUntil`); entity gains `groups` and `isStale`. `ILFestivalKind.observance` is no longer produced here (kept only for the Sangha mock, see "Dependencies") |
| Festivals / UseCase | `Domain/UseCases/Festivals/ILFestivalsUseCase.swift` | `loadMonths(year:today:)`: one year → months. | built; **change**: drop the 365-day loop and the local Rằm / Mùng Một (`ILLunarCalendar`); build days straight from the occurrences in server order; `cachedMonths(year:today:)` for the copy-first render; current year in `Asia/Ho_Chi_Minh` |
| Festivals / State | `Presentation/Scenes/Festivals/ILFestivalsStateModel.swift` | Tab, subtitle, current month id, months, day rows. | built; **change**: `ILFestivalsTab` → `ILFestivalsFilter` (`.all`, `.major`, `.group(code)`), `chips` (label + count + selected), row `groupText` + `isMajor`, `staleNote`, `footer` (`.none` / `.loading` / `.retry`), full-screen `failure` (offline / could not load) |
| Festivals / ViewModel | `Presentation/Scenes/Festivals/ILFestivalsViewModel.swift` | Inputs `viewDidLoad`, `tabSelected`, `loadMoreTriggered`, `dayTapped`, `backTapped`; nav `.goBack`, `.openFestivalDetail(code:date:)`. | built; **change**: `maxYear` 2200 → 2100; copy-first load; `filterSelected`, `retryTapped`, `loadMoreRetryTapped` inputs; any row opens the detail; filtering / counting off the main actor |
| Festivals / ViewController + Views | `ILFestivalsViewController.swift`, `Views/ILFestivalsItemView.swift` | Sticky header band + three chips, months, scroll to current month, incremental append on load more; first-load failure is a toast. | built; **change**: chips from state (horizontally scrolling row inside the band), group text + major mark in the item, stale note under the header, footer retry row, full-screen failure state with "Thử lại" (no toast), intro without the temples sentence |
| Festivals / Coordinator | `ILFestivalsCoordinator.swift` | `.goBack` pop + `finish()`; `.openFestivalDetail` → child detail coordinator. | built |
| FestivalDetail / Entity | `Domain/Entities/ILFestivalDetailEntity.swift` | Event + occurrence merged, group names, `daysUntil`. | built; **add** `isMajor`, `isStale`; `countdown` replaces `daysUntil` |
| FestivalDetail / UseCase | `Domain/UseCases/FestivalDetail/ILFestivalDetailUseCase.swift` | `loadDetail(code:date:today:)` — loads the year of `date`, finds event + occurrence, `.notFound` otherwise. | built; **change**: goes through the shared repository (memory hit, no request, when the list or Home loaded the year) |
| FestivalDetail / State + ViewModel | `ILFestivalDetailStateModel.swift`, `ILFestivalDetailViewModel.swift` | Line split + list-marker strip (already BR-CAL-14-shaped), countdown, weekday; every section has an `…EmptyText`. | built; **change**: remove `imageEmptyText`, `kindText` fallback, `aboutEmptyText`, `practicesEmptyText`, `sutra*`, `hosts*`; add `showsAbout` / `showsPractices` / `showsKind`, `isMajor`, `staleNote`; not-found → no retry |
| FestivalDetail / ViewController + Views | `ILFestivalDetailViewController.swift`, `Views/ILFestivalDetailHeroView.swift`, `…KindRowView`, `…AboutView`, `…DateCardView`, `…ListCardView`, `…ErrorView` | Sticky band + nav bar, hero, sections, loading / error. | built; **change**: hide empty sections, remove the sutra / hosts cards, major mark in the kind row, hero default image (⚠️ product), error view without retry for not-found |
| FestivalDetail / Coordinator | `ILFestivalDetailCoordinator.swift` | Push; `.back` → pop + `finish()`. | built |
| Home / UseCase | `Domain/UseCases/Home/ILHomeUseCase.swift` (`loadBuddhistEventMonths(around:)`) | Today: every occurrence of the calendar year of `date`, grouped by month, months without occurrences dropped, tone by group. | built; **replace** with `loadEventBlock(today:)` → six `ILHomeEventMonthEntity` from the current month (Vietnam time), loading the next year when needed, rows from `ILCalendarRules.homeBlockMonth` |
| Home / Entity + State | `Domain/Entities/ILHomeEntity.swift` (`ILHomeEventMonthEntity`, `ILHomeEventItemEntity`), `ILHomeStateModel.swift` | Month id / label / events; state counts `totalEventsCount` and cuts to 3 in `ILHomeViewModel`. | built; **change**: month carries `shown`, `moreCount`, `loadFailed` (offline / could not load); block carries `isStale`; the ViewModel no longer cuts or counts |
| Home / ViewModel | `ILHomeViewModel.swift` | `loadBuddhistEvents()` (failure ignored → block empty), `eventTapped`, `.openFestivals`, `.openFestivalDetail`. | built; **change**: failure state + `eventsRetryTapped` input, empty-month message, stale note |
| Home / View | `Views/ILHomeEventsCarouselView.swift` | Month cards, rows, "+N sự kiện khác" row (opens the calendar), "Tất cả". | built; **change**: empty-month card, failure card with retry in place of the cards, stale note |
| Legacy (remove) | `Domain/Entities/ILBuddhistEventEntity.swift`, `Domain/UseCases/BuddhistEvent/ILBuddhistEventUseCase.swift`, `Domain/Repositories/ILBuddhistEventRepository.swift`, `Data/Repositories/ILBuddhistEventRepositoryImpl.swift`, `Data/DataSources/Local/ILBuddhistEventLocalDataSource.swift`, `ILBuddhistEventTemplateMO.swift`, `InnerLampTests/ILBuddhistEventRepositoryTests.swift`, `ILBuddhistEventUseCaseTests.swift`, DI `buddhistEventLocalDataSource` / `makeBuddhistEvent…` | Old local event catalogue (Core Data). No screen calls it any more (`makeBuddhistEventUseCase()` has no caller). | **remove** (BR-CAL-01, BR-CAL-05); the `ILBuddhistEventTemplateMO` entity leaves the Core Data model in the next model version (shared with Memorial's planned version) |
| Localization | `Resources/Localization/vi.json` | `festivals.*`, `festivalDetail.*`, `home.events.*`, `catalog.error.*`. | built; **remove** `festivals.observance.*`, `festivals.tab.observance`, `festivalDetail.*.empty`, `festivalDetail.sutra.*`, `festivalDetail.hosts.*`; **change** `festivals.item.countdown.days` to "Còn %d ngày" (BR-CAL-13); **add** stale note, retry row, empty month, block failure, major mark label — copy ⚠️ product |
| Tests | `InnerLampTests/ILCalendarEventsTests.swift`, `ILFestivalsUseCaseTests.swift`, `ILFestivalsViewModelTests.swift`, `ILFestivalDetailUseCaseTests.swift`, `ILFestivalDetailViewModelTests.swift`, `ILHomeUseCaseTests.swift`, `ILHomeViewModelTests.swift` | Repository (year query, mapping, failures), use cases, ViewModels. Written, build-verified, not run. | built; **update** for every change above; `test_loadEvents_sendsYearQuery_toAuthenticatedEndpoint` flips to "no Authorization header" in Phase 6 |
| Product vectors (planned) | `InnerLampTests/ILCalendarProductVectorTests.swift` + `InnerLampTests/ProductVectors/calendar/{countdown,ordering,home-block}.json` + `Scripts/sync-product-vectors.sh` | Runs every case of the three client files against `ILCalendarRules` (criterion 23). See "Product vectors". | planned |

## Navigation flow

```
ILHomeCoordinator
  ├─ events block "Tất cả" / "+N sự kiện khác" → .openFestivals → showFestivals() → ILFestivalsCoordinator (child)
  └─ events block row                         → .openFestivalDetail(code, date) → ILFestivalDetailCoordinator (child)
ILSanghaCoordinator  ("Lịch lễ")              → .openFestivals → ILFestivalsCoordinator (child)
ILDeityCoordinator   (festival link)          → .openFestivals → ILFestivalsCoordinator (child)

ILFestivalsCoordinator
  push ILFestivalsViewController
     (any row, Rằm / Mùng Một included) → .openFestivalDetail(code, date) → ILFestivalDetailCoordinator (child)
     (Back)                             → .goBack → pop, finish()
ILFestivalDetailCoordinator
  push ILFestivalDetailViewController
     (Back)                             → .back → pop, finish()
```

## Step-by-step Flow

Home can need two years at once (window across December) and the festival calendar loads year after
year, so the year load is written out once and the surfaces reference it.

### Load one year (shared — `ILCalendarEventRepositoryImpl.loadEvents(year:)`)

```
Step Y-1 — Memory
- Trigger: any surface asks for year Y
- Action: Y already loaded from the server in this app session → return it, isStale = false, stop
  (no request; a content change shows on the next app launch — FR-CAL-010 "next load")
Step Y-2 — Device copy for the first render (planned)
- Caller: before awaiting Y-3 the surface calls cachedEvents(year: Y); a copy is rendered at once
  (criterion 20, NFR-CAL-03); no note yet
Step Y-3 — Fetch
- Pre-condition: none — no session needed once public (Phase 6); until then the endpoint attaches the
  access token and a guest gets 401
- API: GET /v1/calendar/events?year=Y (CalendarEventsEndpoint; no Authorization after Phase 6, no
  X-API-Key ever)
    - Success → Step Y-4
    - offline / timeout → copy exists: return it, isStale = true; none: throw .offline
    - 429 / 5xx / 401 (before Phase 6) / unreadable → copy exists: return it, isStale = true;
      none: throw .loadFailed (criterion 22: no automatic retry)
Step Y-4 — Keep
- Action: memory[Y] = result; localDataSource.write(dto, year: Y) and deleteYears(before: current
  year) — best effort, a failure is logged (path and year only) and ignored; return isStale = false
```

### Open the festival calendar

```
Step F-1 — Current year
- Trigger: viewDidLoad
- Action: Y = year of today in Asia/Ho_Chi_Minh (criterion 3)
Step F-2 — Load Y (flow above)
    - copy (Y-2) → render months, then replace them when Y-3 returns
    - success → months; stale → months + stale note
    - throw → full-screen failure (offline / could not load) + "Thử lại" → back to F-2 (criterion 21)
Step F-3 — Build (off the main actor)
- Action: occurrences in server order → days (countdown via ILCalendarRules with the device date)
  → months → apply the chosen filter, count every chip (criteria 4, 7–8)
Step F-4 — Scroll to the current month, once
```

### Load the next year (scroll near the end)

```
Step M-1 — Guard
- Pre-condition: no load in flight, last loaded year L < 2100 (criterion 10)
Step M-2 — Load L + 1 (flow above)
    - success / stale → append its months only (incremental, AGENTS §4.6), recount chips, keep filter
      (criterion 9); a stale year adds the stale note
    - throw → footer retry row; tapping it repeats M-2 (criterion 11)
```

### Open an event detail

```
Step D-1 — Trigger
- Trigger: a festival-calendar row or a Home block row → (code, solar date)
- Action: Y = Gregorian year of the solar date (a lunar-12th-month event in January is still asked
  with its solar year, BR-CAL-02)
Step D-2 — Load Y (flow above; normally a memory hit, no request)
    - throw → error state (offline / could not load) + retry → D-2
Step D-3 — Find
- Action: event with code + its occurrence on that day
    - missing → not-found state, no retry, Back only (criterion 14)
    - found → render, hiding empty sections (criterion 13); stale → note
```

### Home's events block

```
Step H-1 — Window
- Trigger: Home appears (and "Thử lại" on the block)
- Action: months = current month (Asia/Ho_Chi_Minh) + the next five; years = the one or two solar
  years they span
Step H-2 — Load each year (flow above), concurrently
    - both fail with no copy → the block shows the failure message + retry in place of its cards
      (criterion 21)
    - one fails with no copy → its months show the failure message, the others their rows (⚠️ default)
Step H-3 — Rows per month
- Action: ILCalendarRules.homeBlockMonth(occurrences of the month) → shown rows + moreCount;
  a month with none → empty-month card (criteria 16–17); any stale year → block stale note
```

## Server sync

Contract: innerlamp-be `docs/specs/api/openapi.yaml` @ 0eb7d1f, operation `calendarEvents`
(`GET /v1/calendar/events`). Schemas `CalendarEventsEnvelope` / `CalendarEvent` and the error codes
live there; this spec does not copy them. Planned changes the app adopts: backend `requirements.md`
v3.0 E4 (public), E13 (`is_major`, `sort_order`, `recurrence`), E17 (`Cache-Control: public, max-age`
for an explicit year), E22 (`X-API-Key` website-only; absent = served), E23 (per-IP limit → 429).
iOS-only decisions:

- `year` is always sent, so every response is the cacheable one; `URLSession` keeps its default
  protocol cache policy, so a fresh `max-age` response may come from the HTTP cache. The device copy
  of FR-CAL-007 is the app's own file, not `URLCache` (which the system may purge).
- The three v3.0 fields are decoded as optional until the contract marks them required. Against
  today's backend that means: no major mark, an empty "Lễ lớn" filter, no home tier 1, and Rằm /
  Mùng Một in tier 2. The app reads Rằm / Mùng Một only from `recurrence == lunar_monthly`, never from a
  code or a name.
- The Buddhist group of BR-CAL-15 is the group code `buddhist` (the contract's example and seed code);
  every other group is data and is shown by its `name`.
- `is_public_holiday` is decoded and not displayed (product §3.1.1 shows no holiday mark); the app never
  adds a day (BR-CAL-11).
- `image_url` is used as is; `null` → the default image (⚠️ product).

## Product vectors

The three client files are the only test data for BR-CAL-12, 13 and 15 on iOS (`event-placement.json`
is backend-only, product §4.1).

- `Scripts/sync-product-vectors.sh` (the same script Memorial's spec plans; whichever feature lands
  first creates it) copies `../innerlamp-be/docs/product/calendar/rules/{countdown,ordering,home-block}.json`
  into `InnerLampTests/ProductVectors/calendar/` and writes the source commit sha and file hashes to
  `InnerLampTests/ProductVectors/calendar/SOURCE`. The copy is a pinned mirror, never edited by hand; a
  mismatch is fixed in innerlamp-be (via `ba-writer`) and re-synced. A bundled copy is needed because
  XCTest runs on a device, which cannot read the sibling checkout.
- `ILCalendarProductVectorTests` loads every case from the test bundle:
  - `countdown.json` → `ILCalendarRules.countdown` with a gregorian calendar; asserts `days` and the label
    kind (`today` / `tomorrow` / `days_left` / `passed`).
  - `ordering.json` → `ILCalendarRules.ordered` (`display_order` → `sortOrder`, `event` → code).
  - `home-block.json` → `ILCalendarRules.homeBlockMonth` (`major` → `isMajor`, `every_lunar_month: true`
    → `recurrence = .lunarMonthly`, `groups` → `groupCodes`); asserts `shown` and `more`.
- None of these needs backend v3.0: the vectors supply the major mark and the display order.

## Dependencies

- `ILSanghaViewModel` builds its (mock) upcoming-day rows from `ILFestivalDayEntity`, `ILFestivalKind`
  (including `.observance`) and `ILFestivalsViewModel.makeDayModel`. Those rows belong to the sangha
  feature, not to this one; the changes here keep those types and that function usable by Sangha (or
  move the pieces Sangha needs into the Sangha scene) and must leave Sangha building.
- `Docs/Specs/Home/` v1.11 still describes the events carousel and an "API contract — calendar events"
  section; this spec replaces those parts (a Phase 9 task points Home's spec here).

## Deliberately stubbed for now

- Nothing is stubbed with a fake call. Waiting on the backend (Phase 6): the public route (criterion 1)
  and the fields behind the major mark, the "Lễ lớn" filter and the home tiers.

## Known drift against product spec v1.1

Listed in `requirements.md` "Pending" with criterion numbers; each has a `[ ]` task in `tasks.md`
Phase 4–9. In short: local Rằm / Mùng Một (BR-CAL-05); "Lễ lớn" = every named event, no group chips
or counts, no group / major on rows (BR-CAL-09, BR-CAL-10, FR-CAL-003); 2200 limit, device-time year,
silent next-year retry (FR-CAL-002, FR-CAL-004); "Chưa có…" placeholders, sutra / temple sections,
not-found retry (BR-CAL-14, FR-CAL-005); home block = whole calendar year, every group, no tiers, empty
months dropped, disappears on failure (BR-CAL-15, FR-CAL-006, FR-CAL-008); no device copy (FR-CAL-007);
toast-only first-load failure on the calendar (FR-CAL-008); signed-in only (FR-CAL-001); vectors not run.

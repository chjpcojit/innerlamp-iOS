# Tasks — Calendar

Version: 1.0
Last updated: 2026-10-15
Status: in-progress — Phase 1–3 built (build-verified, tests not run) except the items left `[ ]`; Phase 4 (product spec v1.1 drift), Phase 5 (device copy) and Phase 7 (product vectors) not started; Phase 6 waits on backend v3.0 (backend `tasks.md` Phase 14–18); Phase 8 (copy) blocked on ⚠️ product

> See `changelog.md` in this folder for the version history of this spec.

Every item traces to a row of `design.md` "Layers & components" or a step of its Step-by-step Flow.
`[x]` only where the code was read on 2026-10-15 and does what product spec v1.1 requires.

## Phase 1 — UI

- [x] `ILFestivalsViewController` on `BaseViewController` (sticky band + nav bar + chips row, month sections, scroll to the current month once, incremental append on load more) and `Views/ILFestivalsItemView`
- [x] `ILFestivalDetailViewController` (sticky band + nav bar, hero via `ILRemoteImageView`, kind row, about, date card with countdown pill, numbered practices card, loading and error views) and its `Views/`
- [x] Home's `ILHomeEventsCarouselView` (month cards, rows, "+N sự kiện khác" row, "Tất cả")
- [ ] Visual QA on device against the prototype (`festVals`, `festDetail`, Home item 4), light + dark, Dynamic Type, long names

## Phase 2 — Domain + Presentation logic

- [x] `ILCalendarEventsEntity` / `ILCalendarGroupEntity` / `ILCalendarEventEntity` / `ILCalendarOccurrenceEntity` (Foundation only)
- [x] `ILFestivalsEntity`, `ILFestivalsUseCaseImpl.loadMonths(year:today:)`, `ILFestivalsStateModel`, `ILFestivalsViewModel` (load current year, load more one year at a time with an in-flight guard, back, tap → detail)
- [x] `ILFestivalDetailEntity`, `ILFestivalDetailUseCaseImpl.loadDetail(code:date:today:)` (year of the solar date, `.notFound` when absent), `ILFestivalDetailViewModel` (line split + list-marker strip per BR-CAL-14, weekday, countdown, retry)
- [x] Home: `ILHomeUseCaseImpl.loadBuddhistEventMonths(around:)`, `ILHomeViewModel` `eventTapped` → `.openFestivalDetail`, "Tất cả" / "+N" → `.openFestivals`
- [x] Countdown labels Hôm nay / Ngày mai / N days / Đã qua from the device date (BR-CAL-13; copy fixed in Phase 4)
- [x] Both dates on every server row and on the detail, "(nhuận)" for a leap month, as the server sends them (BR-CAL-08)
- [x] Entry points: Home, Sangha ("Lịch lễ"), Deity → `makeFestivalsCoordinator`; Home + Festivals → `makeFestivalDetailCoordinator` (criterion 2)
- [x] Coordinators + `DIContainer.makeFestivals…` / `makeFestivalDetail…`
- [x] Unit tests written and build-verified, not run (XCTest needs a device): `ILFestivalsUseCaseTests`, `ILFestivalsViewModelTests`, `ILFestivalDetailUseCaseTests`, `ILFestivalDetailViewModelTests`, `ILHomeUseCaseTests`, `ILHomeViewModelTests`

## Phase 3 — API integration

- [x] Contract `GET /v1/calendar/events` (innerlamp-be `openapi.yaml`, operation `calendarEvents`)
- [x] `ILCalendarEventsDTO` + `ILCalendarEventMapper` (drops occurrences with an unknown event or unparsable date)
- [x] `CalendarEventsEndpoint` (always sends `year`)
- [x] `ILCalendarEventRepositoryImpl` (network → `ILCatalogError` `.offline` / `.loadFailed`)
- [x] `ILCalendarEventsTests` (year query, mapping, failures) — written, build-verified, not run
- [ ] Manual test against the backend (`make run`, `:8080`) on a physical device

## Phase 4 — Product spec v1.1 alignment (drift, no backend change needed)

- [ ] Stop computing Rằm / Mùng Một (BR-CAL-05, criterion 5): remove the 365-day loop, the `ILLunarCalendar` call and the `.observance` days from `ILFestivalsUseCaseImpl`; build days from the occurrences in server order; remove `festivals.observance.*`; update `ILFestivalsUseCaseTests` (no local observance, a server Rằm shown as a normal row)
- [ ] Keep Sangha building (design "Dependencies"): `ILFestivalKind` / `ILFestivalDayEntity` / `makeDayModel` stay usable by `ILSanghaViewModel`, or the pieces it needs move to the Sangha scene; `ILSanghaViewModelTests` unchanged
- [ ] Every row opens the detail, Rằm / Mùng Một included; `eventCode` non-optional (criterion 6); ViewModel test
- [ ] `ILCalendarRules` in `Domain/UseCases/Calendar/` (`countdown`, `ordered`, `homeBlockMonth`) and use it in the Festivals, FestivalDetail and Home ViewModels / use cases instead of the private copies (criteria 4, 13, 16, 23)
- [ ] Countdown copy "Còn %d ngày" on the list as on the detail (BR-CAL-13)
- [ ] Current year (calendar) and current month (home block) in `Asia/Ho_Chi_Minh` (criteria 3, 16); tests with a fixed date near midnight
- [ ] `maxYear` 2100 (FR-CAL-004, criterion 10); update the ViewModel test
- [ ] Filters (FR-CAL-003, criteria 7–9): `ILFestivalsFilter` (`.all`, `.major`, `.group(code)`), chips built from the response's `groups` in order with counts (⚠️ default format "Lễ lớn (10)"), filter kept and counts updated on load more, empty months hidden; remove `festivals.tab.observance`; ViewModel tests per filter and after load more. "Lễ lớn" filters on `isMajor` (empty until Phase 6)
- [ ] Rows show the group names and the major mark (criterion 4); `ILFestivalsItemView` layout
- [ ] Next-year failure → footer retry row, tap retries (FR-CAL-004, FR-CAL-008, criterion 11); test
- [ ] First-load failure → full-screen state with offline / could-not-load title and "Thử lại", no toast (FR-CAL-008, criterion 21); tests for both errors and a successful retry
- [ ] Detail (FR-CAL-005, BR-CAL-14, criterion 13): hide empty image text / kind / about / practices sections; remove the "Kinh nên tụng" and "Chùa tổ chức" cards, their state fields and `festivalDetail.sutra.*` / `festivalDetail.hosts.*` / `festivalDetail.*.empty`; major mark in the kind row; tests for an event with empty guidance and no image
- [ ] Detail default image when `imageURL` is `nil` — blocked on ⚠️ product (which image); until then the hero keeps its placeholder background, no text
- [ ] Detail not-found → no retry, Back only (criterion 14); test
- [ ] Home block (FR-CAL-006, BR-CAL-15, criteria 16–18): `loadEventBlock(today:)` → six months from the current month, the next year loaded concurrently when the window crosses December, rows and "+N" from `ILCalendarRules.homeBlockMonth` (Buddhist group only), empty-month card; remove `prefix(3)` / `totalEventsCount` from `ILHomeViewModel`; `ILHomeUseCaseTests` for a window inside one year, across the year end, an empty month
- [ ] Home block failure → message + retry in place of the cards (both years failed) or on the failed year's cards (⚠️ default), never an empty block (FR-CAL-008, criterion 21); `ILHomeViewModelTests`
- [ ] Festival-calendar intro without the "temples holding each event" sentence (product §1.2)
- [ ] Build months, filters and counts off the main actor (NFR-CAL-03, AGENTS §4.6, criterion 24)
- [ ] Remove the unused local catalogue `ILBuddhistEvent*` (entity, use case, repository + impl, local data source, `ILBuddhistEventTemplateMO`, DI entries, `ILBuddhistEventRepositoryTests`, `ILBuddhistEventUseCaseTests`); drop the Core Data entity in the next model version (shared with Memorial's); fix the `ILDeityRepository` doc comment that mentions `ILBuddhistEventError` (BR-CAL-01, BR-CAL-05)

## Phase 5 — Device copy (FR-CAL-007, criteria 19–20)

- [ ] DTOs `Codable`; `ILCalendarEventLocalDataSource` (`read` / `write` / `deleteYears(before:)`, one JSON file per year in `Application Support/CalendarEvents/`, atomic writes) — ⚠️ default storage
- [ ] `ILCalendarEventRepositoryImpl` as an actor: memory per session, `cachedEvents(year:)`, `loadEvents(year:)` → `ILCalendarYearResult` with `isStale`; write copy + prune after a server success; 429 / 5xx / 401 / offline / unreadable → copy or throw (Step-by-step Flow Y-1…Y-4, criterion 22)
- [ ] One shared repository instance in `DIContainer` (`lazy var calendarEventRepository`)
- [ ] Copy-first render on the festival calendar, the detail and the home block (⚠️ default), stale note on each when the refresh fails
- [ ] Repository tests: memory hit makes no request; success writes the copy; offline / 5xx / 429 with a copy → `isStale`; without → `.offline` / `.loadFailed`; old years pruned; a corrupt file is ignored
- [ ] Manual QA in airplane mode: calendar, detail and Home after one online visit; first visit offline (FR-CAL-007, FR-CAL-008 scenarios)
- [ ] Measure NFR-CAL-03 on device: ≤ 2 s on 4G, ≤ 0.5 s from the copy (criterion 24)

## Phase 6 — Backend v3.0 fields and public route — waits on innerlamp-be `tasks.md` Phase 14–18 (openapi update in Phase 18)

- [ ] Confirm `is_major`, `sort_order`, `recurrence` and the public route are in innerlamp-be `openapi.yaml`, then bump this spec's `Contract:` line
- [ ] DTO + mapper + entity: `isMajor`, `sortOrder`, `recurrence` (`ILCalendarRecurrenceKind`, unknown → `.unknown`); mapper tests with and without the fields
- [ ] Major mark on rows and on the detail, "Lễ lớn" filter on `isMajor`, home tiers 1 and 3 live (BR-CAL-10, BR-CAL-15, criteria 4, 8, 13, 16)
- [ ] Public route (FR-CAL-001, criterion 1): `CalendarEventsEndpoint.requiresAuth = false`, no `X-API-Key`; `ILCalendarEventsTests` asserts no `Authorization` header; manual QA as a guest (guest preview) and signed in — same occurrences, no sign-in prompt
- [ ] Manual QA on device against the seeded backend: 2026-05-31 lists Lễ Phật đản above Rằm; February's home card per BR-CAL-15 (needs backend Phase 16 seed)

## Phase 7 — Product vectors (criterion 23, BR-CAL-12, BR-CAL-13, BR-CAL-15)

- [ ] `Scripts/sync-product-vectors.sh` (create it if Memorial has not yet; add the calendar folder): copies `../innerlamp-be/docs/product/calendar/rules/{countdown,ordering,home-block}.json` into `InnerLampTests/ProductVectors/calendar/`, writes commit sha + hashes to `SOURCE`; the copy is never hand-edited; add the files to the test target's resources
- [ ] `ILCalendarProductVectorTests` running **every case** of `countdown.json`, `ordering.json` and `home-block.json` against `ILCalendarRules` (`event-placement.json` is backend-only)

## Phase 8 — Copy — blocked on ⚠️ product

- [ ] Strings for the stale note, the offline / could-not-load titles and messages, the retry row, the home block's empty month and failure, the not-found state, the major mark label — once product gives the copy; until then keep `catalog.error.*` / `festivalDetail.error.*`

## Phase 9 — Documentation

- [ ] Refresh `Presentation/Scenes/Festivals/README.md` (still says "Lễ lớn" = named events, local Rằm / Mùng Một, 2200, no cache) and `Presentation/Scenes/FestivalDetail/README.md` (cites `Docs/Specs/FestivalDetail/`, "Chưa có…" sections) to cite this spec
- [ ] `Docs/Specs/Home/`: replace the events-carousel criterion and the "API contract — calendar events" section with a pointer to `Docs/Specs/Calendar/` (`il-spec-ios` update of Home)
- [ ] Remove the superseded iOS docs (later docs-pipeline step, after this spec is approved): `Docs/Specs/FestivalDetail/`, `Docs/Assumptions/Festivals/AS-Festivals-001…002`, `Docs/Assumptions/FestivalDetail/AS-FestivalDetail-001…002`, `Docs/Assumptions/Home/AS-Home-003`, `Docs/Tech-Debt/FestivalDetail/TD-FestivalDetail-001…002`, `Docs/Tech-Debt/Home/TD-Home-003`; update the code comments and READMEs that cite them
- [ ] `Docs/Knowledge/features/calendar.md` (OKF) — after Phase 4–7 are verified end to end (`Docs/Specs/OKF.md`)

## Deferred (separate feature or later version, not blocking Calendar)

- Lunar calendar screen, lunar day detail, daily picture — product v1.x (`Docs/Specs/LunarCalendar/`, `Docs/Specs/LunarDayDetail/` today).
- "Nhắc tôi ngày này" — later, ADR-0001 notification list and push.
- "Kinh nên tụng" / "Chùa tổ chức" — no data source (product §1.2).
- Previous / next event on the detail — FR-CAL-009, website only.

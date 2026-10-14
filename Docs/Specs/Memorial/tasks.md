# Tasks — Memorial

Version: 2.0
Last updated: 2026-10-14
Status: in-progress — Phase 1–5 built (build-verified, tests not run) except the items left `[ ]`; Phase 6 (product spec v1.0 drift) and Phase 7 (reminders) not started; Phase 8 (portrait) blocked on the backend photo route

> See `changelog.md` in this folder for the version history of this spec.

Every item traces to a row of `design.md` "Layers & components" or a step of its Step-by-step Flow.
`[x]` only where the code was read and does what the product spec v1.0 now requires.

## Phase 1 — UI

- [x] `ILMemorialViewController` on `BaseViewController` (list: nav bar, highlight card, "THEO NGÀY GIỖ SẮP TỚI" rows, empty state `ILMemorialEmptyView`, sticky "Thêm người thân", "Xem gia phả"; toast via `ILAlert.success`)
- [x] `ILMemorialEditViewController` (portrait placeholder, name + error, relationship chips, calendar toggle, day/month/year menus, preview card, note, reminder card, Save/Delete)
- [x] Feature views under `Scenes/Memorial/Views/` and the generic design-system pieces (`ILSegmentedToggleView`, `ILSwitchRowView`, `ILMenuFieldView`)
- [ ] Visual QA against the prototype (`gio`, `gioEmpty`, `gioEdit`) on device, light + dark, long names, Dynamic Type

## Phase 2 — Domain + Presentation logic

- [x] `ILLunarCalendar.lunarToSolar(day:month:year:isLeap:)` (day 30 → 29 in a short month, BR-MEM-06) + `ILLunarToSolarTests`
- [x] `ILMemorialEntity` (+ `ILMemorialRelationship`, `ILMemorialCalendarKind`, `ILMemorialReminder`, `ILMemorialNextAnniversary`, `ILMemorialItem`)
- [x] `ILMemorialRepository` protocol + `ILMemorialError`
- [x] `ILMemorialUseCaseImpl`: `loadItems` (sort soonest, ties by name), `nextAnniversary` (lunar regular month in lunar years −1/0/+1, solar month-end clamp), `makeNewEntry` (FR-MEM-003 defaults), `isValid(name:)`, `save` (trims), `delete`
- [x] `ILMemorialFormatter` (days label, eyebrow, ordinal label, stored date, solar line, reminder line)
- [x] `ILMemorialStateModel`, `ILMemorialEditStateModel` (no UIKit)
- [x] `ILMemorialViewModel` + `ILMemorialEditViewModel` (`Input -> Output`, nav events, empty-name error cleared on typing, preview recomputed on every change, lead/time fixed choices of BR-MEM-11)
- [x] `ILMemorialCoordinator` (pop + toast hand-off), `DIContainer.makeMemorial…`, `ILHomeCoordinator.showMemorial()` (Home v1.7)
- [x] Unit tests written and build-verified, not run (XCTest needs a device): `ILMemorialUseCaseTests`, `ILMemorialViewModelTests`, `ILMemorialEditViewModelTests`

## Phase 3 — Localization

- [x] `memorial.*` keys in `vi.json` for all v1.3 copy (no hardcoded text)

## Phase 4 — API integration

- [x] Contract `/v1/memorials` (innerlamp-be `openapi.yaml`)
- [x] `ILMemorialDTO` + `ILMemorialMapper` (relationship enum, known-year lunar ↔ solar, unknown-year day/month)
- [x] Endpoint conformances (list / create / update / delete)
- [x] Server-first `ILMemorialRepositoryImpl` with the Core Data offline cache (`replaceAll`, `upsert`, `delete`); DELETE 404 = success
- [x] Mapper and repository tests (success, offline, 401, 409, 400, 404) — written, build-verified, not run
- [x] Solar day menu limited per month (Feb 29) so the server never sees 31 April
- [x] Offline save/delete refused with "Không có kết nối mạng. Vui lòng thử lại." (FR-MEM-010)
- [x] 100-entry limit message on 409 `MEMORIAL_LIMIT_REACHED` (BR-MEM-02)
- [x] Network logging records method, path, status and timing only — no names or notes (NFR-MEM-02, verified in `NetworkService`)
- [ ] Manual test against the backend (`make run`, `:8080`) on a physical device

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Memorial/README.md` created
- [ ] Refresh that README — it still says "no server sync" and "DTO N/A" (stale since v1.3); list the v2.0 drift
- [ ] Close `Docs/Assumptions/Memorial/AS-Memorial-001…006` as superseded by product spec v1.0 (status `Invalidated`/`Validated` + Outcome citing the product IDs, and the `@ai: assumption` markers in code pointing at the product IDs) — separate step after this spec is reviewed, see `changelog.md` v2.0. Deleting the files needs an explicit user decision: `AGENTS.md` §10.3 says entries are never deleted
- [ ] `Docs/Knowledge/features/memorial.md` (OKF) — after Phase 6–7 are verified end to end (`Docs/Specs/OKF.md`)

## Phase 6 — Product spec v1.0 alignment (drift)

- [ ] **Product vectors** (criterion 34, NFR-MEM-03, BR-MEM-03…10): add `Scripts/sync-product-vectors.sh` (copies `../innerlamp-be/docs/product/memorial/rules/*.json` into `InnerLampTests/ProductVectors/memorial/`, records commit sha + hashes in `SOURCE`; the copy is never hand-edited) and `ILMemorialProductVectorTests` running **every case** of `rules/next-anniversary.json`, `rules/anniversary-ordinal.json` and `rules/death-date-conversion.json`; add the JSON files to the test target's resources
- [ ] Ordinal: `nextAnniversary` returns the raw ordinal (keep `0`); `ILMemorialFormatter.ordinalText` shows no label for `≤ 0` (BR-MEM-09, vector "died today")
- [ ] Leap month (BR-MEM-04, criteria 5, 13): `isLeapMonth` on the entity + Core Data (new model version); leap switch in the form for "Âm lịch"; mapper sends `death_leap_month` when the year is unknown and recovers it from `solarToLunar` when known; leap marker in stored date line / highlight / preview — copy ⚠️ product
- [ ] Strict date of death (BR-MEM-03, BR-MEM-04, criterion 19): strict `lunarToSolar` variant (day 30 in a 29-day month → `nil`, missing leap month → `nil`); use case `validate` rejects it, a date after today and a year < 1900 before any network call; `dateError` on the form — copy ⚠️ product
- [ ] Year menu 1900 → current year (BR-MEM-03, criterion 15); update `test_yearOptions_…NinetySixYears`
- [ ] Name ≤ 100 / note ≤ 1000 checked locally with field errors (FR-MEM-012, FR-MEM-013, criterion 18) — copy ⚠️ product
- [ ] Delete confirmation action sheet before `DELETE` (BR-MEM-12, FR-MEM-005, criterion 24); remove the `AS-Memorial-004` `@ai` marker; tests for confirm / cancel
- [ ] Guest (FR-MEM-001, criterion 2): no token → `.signInRequired`, no server call, no cache read; 401 on load → sign-in prompt instead of the empty state
- [ ] Sign-out (BR-MEM-01, NFR-MEM-02, criterion 3): `ILMemorialRepository.clearCache()` + `ILMemorialLocalDataSource.deleteAll()` called from the logout flow (and `cancelAll()` of Phase 7 once built); cache served offline only for the signed-in account
- [ ] Offline, never loaded (FR-MEM-010, criterion 32): "cannot load offline" state instead of the empty state — copy ⚠️ product
- [ ] Load failure state with retry for non-offline errors (criterion 11) — blocked on ⚠️ product (5xx: cache or error?)
- [ ] Not-found on save (FR-MEM-004, criterion 23): alert, close the form, reload the list
- [ ] Send `reminder.timezone` = device time zone (BR-MEM-11, criterion 27); mapper test
- [ ] Reminder values outside the BR-MEM-11 choices coming from the server — blocked on ⚠️ product (criterion 26)
- [ ] Measure NFR-MEM-01 (100 entries, 4G, ≤ 2 s) on device (criterion 36)

## Phase 7 — Reminders (FR-MEM-008, FR-MEM-009, BR-MEM-11) — `TD-Memorial-001`

- [ ] `ILMemorialReminderScheduling` protocol (Domain) + `ILMemorialNotificationScheduler` (`UNUserNotificationCenter`, identifiers `memorial.<id>`, one request per entry at the BR-MEM-11 moment before the next anniversary, device local time); replace the TODO stubs in `ILMemorialUseCaseImpl` (Step L-5, S-5, D-4)
- [ ] Ask notification permission before the first schedule (criterion 29); denied branch blocked on ⚠️ product
- [ ] `replaceAll` on every list load (server or cache) and after save; `cancel` on delete and reminder off; `cancelAll` on sign-out (criteria 3, 25, 28)
- [ ] Unit tests of the reminder moment for each lead × time against `next-anniversary.json` dates, with a mock scheduler
- [ ] `ILMemorialOSRemindersWriter` (EventKit) + `NSRemindersFullAccessUsageDescription` in Info.plist (FR-MEM-009, criterion 30) — blocked on ⚠️ product (edit/delete/duplicates/denied)
- [ ] Manual QA on device: a reminder fires; a reminder set on another device fires here after opening the book (FR-MEM-008 scenarios)
- [ ] Close `TD-Memorial-001`

## Phase 8 — Portrait (FR-MEM-011) — later, blocked on the backend photo route

- [ ] Photo picker + HEIC → JPEG conversion, 5 MB check, upload/replace/remove against the backend photo routes once they are in `openapi.yaml`; show `photo_url` (`TD-Memorial-002`, backend `TD-001`)

## Deferred (separate feature, not blocking Memorial)

- Family tree ("Gia phả") adding an entry to the book — `genealogy` product spec.

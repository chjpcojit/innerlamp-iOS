# Design — Memorial

Version: 2.0
Last updated: 2026-10-14
Status: in-progress — list, form, server CRUD and offline cache built (build-verified, tests not run); planned: leap month, strict date checks, delete confirmation, guest/sign-out/offline edge cases, reminder scheduler + EventKit, product vectors

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. One feature folder, two screens: the list
(`ILMemorial…`) and the add/edit form (`ILMemorialEdit…`), both owned by `ILMemorialCoordinator`, a
child of `ILHomeCoordinator` (the entry is Home's week-strip link, not a cross-section flow).

How iOS meets the product constraints (product spec v1.0 §2.7, §3.6; see `requirements.md`):

- **Server is the source of truth** (BR-MEM-01): `/v1/memorials` through `ILMemorialRepositoryImpl`;
  Core Data is a read cache used only when offline (FR-MEM-010). The cache must belong to the signed-in
  account and be wiped on sign-out (criterion 3).
- **Client computes** (BR-MEM-05…10): `ILMemorialUseCaseImpl.nextAnniversary` over
  `ILLunarCalendar` (Hồ Ngọc Đức's algorithm, UTC+7). Correctness is proven only by the product vectors
  (row "Product vectors" below), not by restating rules here.
- **Reminders are local** (FR-MEM-008, BR-MEM-11): a scheduler behind a Domain protocol, implemented
  with `UNUserNotificationCenter`; the iOS Reminders app (FR-MEM-009) through EventKit. Both planned.

## Layers & components

| Layer | File | Responsibility | State |
|---|---|---|---|
| Domain / Entity | `Domain/Entities/ILMemorialEntity.swift` | `ILMemorialEntity` (id, name, `ILMemorialRelationship` ×10, `ILMemorialCalendarKind`, day, month, `deathYear: Int?` — a lunar year for a lunar entry, note, `ILMemorialReminder?` {leadDays, hour, minute}, `syncToReminders`, `portraitFileName`), `ILMemorialNextAnniversary` (date, daysUntil, ordinal, lunar day/month of the date), `ILMemorialItem`. Foundation only. | built; **add `isLeapMonth: Bool`** (BR-MEM-04); ordinal must keep `0` (vector) — the "< 1 → no label" rule moves to the formatter |
| Domain / Repository protocol | `Domain/Repositories/ILMemorialRepository.swift` | `loadAll()`, `save(_:)`, `delete(id:)`; `ILMemorialError` (`loadFailed`/`saveFailed`/`deleteFailed`/`offline`/`unauthorized`/`limitReached`/`invalidInput`/`notFound`). | built; **add `clearCache()`** for sign-out and a "no cache" case for criterion 32 |
| Domain / UseCase | `Domain/UseCases/Memorial/ILMemorialUseCase.swift` | `loadItems(now:)` (entries + next anniversary, soonest first, ties by name), `nextAnniversary(for:now:)`, `makeNewEntry()`, `isValid(name:)`, `save` (trims name), `delete`. | built; **add** `validate(_:now:)` returning a field error (name length, note length, date exists strictly / not after today / ≥ 1900 — criteria 18–19); reminder calls go to `ILMemorialReminderScheduling` instead of the TODO stubs |
| Domain / Reminder protocol (planned) | `Domain/Repositories/ILMemorialReminderScheduling.swift` | `replaceAll(with: [ILMemorialItem])`, `cancel(entryID:)`, `cancelAll()`; plus `ILMemorialOSRemindersWriting` for FR-MEM-009. Keeps UserNotifications/EventKit out of Domain. | planned |
| Core util (shared) | `Core/Utils/ILLunarCalendar.swift` | `solarToLunar` (returns `isLeapMonth`), `lunarToSolar(day:month:year:isLeap:)` — resolves day 30 to 29 in a short month (right for BR-MEM-06). | built; **add a strict variant** (or `strict:` flag) that returns `nil` for day 30 in a 29-day month, used only for a date of death (BR-MEM-03, vector "day 30 of a 29-day month is invalid") |
| Data / Local | `Data/DataSources/Local/ILMemorialLocalDataSource.swift` + `ILMemorialMO.swift` (model `InnerLamp 4.xcdatamodel`) | Core Data cache: `fetchAll`, `upsert`, `delete`, `replaceAll`. `deathYear == 0` = unknown, `reminderLeadDays == -1` = off. | built; **add** `isLeapMonth`, the owning account id (or wipe on sign-out — criterion 3), `deleteAll()`; needs a new model version |
| Data / Remote | `Data/DataSources/Remote/MemorialsListEndpoint.swift`, `MemorialCreateEndpoint.swift`, `MemorialUpdateEndpoint.swift`, `MemorialDeleteEndpoint.swift` | One operation per file (cited below). | built |
| Data / DTO + Mapper | `Data/DTOs/ILMemorialDTO.swift`, `Data/DTOs/Mappers/ILMemorialMapper.swift` | Wire ↔ entity, incl. lunar ↔ solar conversion of a known-year date (see "Server sync"). | built; **change**: send `death_leap_month` from the entity when the year is unknown; recover `isLeapMonth` from `solarToLunar` when the year is known; send `reminder.timezone`; use the strict conversion |
| Data / Repository impl | `Data/Repositories/ILMemorialRepositoryImpl.swift` | Server first; cache only when offline (entries without a numeric id are skipped); best-effort cache writes after a successful write. | built; **change**: serve the cache only for the signed-in account; distinguish "offline, no cache" |
| Data / Reminder scheduler (planned) | `Data/Services/ILMemorialNotificationScheduler.swift` | `UNUserNotificationCenter`: one request per entry, identifier `memorial.<id>`, trigger = BR-MEM-11 moment before the next anniversary in device local time; `replaceAll` removes every pending `memorial.*` request first. Asks permission on first use. | planned (`TD-Memorial-001`) |
| Data / Reminders app writer (planned) | `Data/Services/ILMemorialOSRemindersWriter.swift` | EventKit `EKReminder` with a due date/alarm; needs `NSRemindersFullAccessUsageDescription`. Behavior on edit/delete/duplicates is ⚠️ product (requirements criterion 30). | planned, blocked |
| Presentation / Formatter | `Presentation/Scenes/Memorial/ILMemorialFormatter.swift` | Days label, eyebrow, ordinal label (BR-MEM-09 label table), stored date line, solar line, reminder line. | built; **add** leap marker in the stored date line; ordinal `≤ 0` → no label |
| Presentation / State | `ILMemorialStateModel.swift`, `ILMemorialEditStateModel.swift` | List: subtitle, highlight, rows, empty flag, banner. Form: option lists, `nameError`, preview lines, reminder options, `canDelete`, `isSaving`. | built; **add** list error / offline-empty / sign-in states, form `noteError` / `dateError`, `isLeapMonth`, `showsLeapSwitch` |
| Presentation / ViewModel | `ILMemorialViewModel.swift`, `ILMemorialEditViewModel.swift` | `Input -> Output`; nav events `ILMemorialNavEvent` (`.back`, `.addEntry`, `.editEntry(entity)`, `.openFamilyTree`) and `ILMemorialEditNavEvent` (`.back`, `.saved(message)`, `.deleted(message)`). | built; **change**: year options 1900…current year; delete goes through a confirm step; `.notFound` on save closes and reloads; load errors no longer collapse to empty; **add** `.signInRequired` nav event |
| Presentation / Coordinator | `ILMemorialCoordinator.swift` | Pushes list and form; pops on save/delete and hands the message to the list. | built; **add** reload on `.back` after a not-found save, and routing to sign-in for a guest |
| Presentation / ViewController | `ILMemorialViewController.swift`, `ILMemorialEditViewController.swift` | `setupViews` / `setupConstraints` / `bindViewModel`. | built; **add** delete confirmation action sheet, leap switch, error/offline states |
| Presentation / Views | `Scenes/Memorial/Views/` | `ILMemorialHighlightCardView`, `ILMemorialRowView`, `ILMemorialChipGroupView`, `ILMemorialPreviewCardView`, `ILMemorialReminderCardView`, `ILMemorialEmptyView`; reuses `ILNavBar`, `ILChip`/`ILChipFlowView`, `ILInputCardView`, `ILButton`, `ILStateView`, `ILAvatarView`. | built |
| Design system | `Common/DesignSystem/Components/` | `ILSegmentedToggleView`, `ILSwitchRowView`, `ILMenuFieldView`, `ILAlert.success` toast via `ILAlertPresenter`; icons `chevronDown` / `checkmark`. | built |
| Home (modification) | `ILHomeWeekCalendarView.swift`, `ILHomeViewController.swift`, `ILHomeViewModel.swift` (`.openMemorial`), `ILHomeCoordinator.swift` (`showMemorial()`) | The "Sổ giỗ" link — `Docs/Specs/Home/` v1.7. | built |
| Sign-out hook (planned) | the logout use case (Profile) | Calls `ILMemorialRepository.clearCache()` and `ILMemorialReminderScheduling.cancelAll()` (criterion 3). | planned |
| DI | `App/DIContainer.swift` | `makeMemorialUseCase/Repository/ViewModel/EditViewModel/Coordinator`, `memorialLocalDataSource`. | built; **add** scheduler + writer |
| Localization | `Resources/Localization/vi.json` | All copy under `memorial.*`. | built; **add** leap, too-long, date-invalid, delete-confirm, offline-no-cache, sign-in keys (copy ⚠️ product) |
| Tests | `InnerLampTests/ILMemorialUseCaseTests.swift`, `ILMemorialViewModelTests.swift`, `ILMemorialEditViewModelTests.swift`, `ILMemorialMapperTests.swift`, `ILMemorialRepositoryTests.swift`, `ILMemorialTestSupport.swift`, `ILLunarToSolarTests.swift` | Use case, ViewModels, mapper, repository (success, offline, 401, 409, 400, 404). Written, build-verified, not run. | built |
| Product vectors (planned) | `InnerLampTests/ILMemorialProductVectorTests.swift` + `InnerLampTests/ProductVectors/memorial/*.json` + `Scripts/sync-product-vectors.sh` | Runs every case of the three product files (criterion 34). See "Product vectors". | planned |

## Navigation flow

```
ILHomeCoordinator
  └─ .openMemorial → showMemorial() → ILMemorialCoordinator (child)
       push ILMemorialViewController                         (list)
       guest / 401 on load          → .signInRequired   → sign-in prompt (planned)
       (Thêm người thân)            → .addEntry          → push ILMemorialEditViewController (add)
       (highlight card / row tap)   → .editEntry(entity) → push ILMemorialEditViewController (edit)
       (Xem gia phả)                → .openFamilyTree    → child ILFamilyTreeCoordinator
       (form Lưu ok / Xóa confirmed)→ .saved / .deleted  → pop, list reloads + toast
       (form Lưu → 404)             → alert, pop, list reloads (planned)
       (Back)                       → .back              → finish() → Home
```

## Step-by-step Flow

### Load the book (list `viewDidLoad`, return from the form)

```
Step L-1 — Session check (planned)
- Trigger: list appears
- Pre-condition: none
- Action: no access token (guest preview) → .signInRequired, stop (criterion 2). Nothing is read
  from the cache.
Step L-2 — Fetch
- Action: GET /v1/memorials (MemorialsListEndpoint)
    - Success → Step L-3
    - offline/timeout → cache of this account non-empty: use it, go to Step L-4 (criterion 31);
      empty: "cannot load offline" state, stop (criterion 32, planned)
    - 401 → sign-in prompt (planned), cache not shown
    - other → error state with retry (criterion 11, planned; ⚠️ product)
Step L-3 — Refresh cache
- Action: localDataSource.replaceAll(entries) — best effort, a failure is logged and ignored
Step L-4 — Compute and show
- Action: nextAnniversary per entry → sort (daysUntil, then name) → ILMemorialStateModel
Step L-5 — Re-plan reminders (planned; today a TODO stub)
- Action: reminderScheduler.replaceAll(with: items) — removes every pending `memorial.*` request,
  then adds one per entry with a reminder (criterion 28). Runs after a cache read too, so a reminder
  turned on from another device is planned on this one (FR-MEM-008).
```

### Save (form "Lưu")

```
Step S-1 — Validate locally
- Trigger: Save tapped, not already saving
- Action: useCase.isValid(name:) today; planned useCase.validate(entry, now) adds name ≤ 100,
  note ≤ 1000, and — when the year is known — strict conversion (no day-30 fallback, leap month
  must exist), year ≥ 1900, date ≤ today (criteria 17–19)
    - Failure → field error on the form, nothing sent, stop
Step S-2 — Map
- Action: ILMemorialMapper.toRequest(entry) (see "Server sync")
Step S-3 — Write
- Action: numeric id → PUT /v1/memorials/{id}; local UUID → POST /v1/memorials
    - Failure → mapped ILMemorialError → alert per the requirements' Error → UI table; form stays
      usable; 404 → alert, pop, list reloads (criterion 23, planned)
Step S-4 — Cache
- Action: localDataSource.upsert(saved) — best effort
Step S-5 — Reminder (planned; today a TODO stub)
- Action: reminderScheduler.replaceAll after the list reload of Step S-6, or schedule this entry
  directly; when reminder + syncToReminders: osRemindersWriter.add (⚠️ product, criterion 30)
Step S-6 — Close
- Action: .saved(message) → coordinator pops → list reloads (Load flow) and shows the toast
```

### Delete (form "Xóa khỏi sổ giỗ", edit mode only)

```
Step D-1 — Confirm (planned; today the delete starts immediately)
- Trigger: delete tapped
- Action: action sheet "Xóa" (destructive) / "Hủy" (criterion 24)
    - Hủy → nothing changes, stop
Step D-2 — Delete
- Action: DELETE /v1/memorials/{id} (MemorialDeleteEndpoint)
    - 404 → treated as success
    - other failure → alert, form stays usable, stop
Step D-3 — Cache
- Action: localDataSource.delete(id:) — best effort
Step D-4 — Reminder (planned; today a TODO stub)
- Action: reminderScheduler.cancel(entryID:) and remove the Reminders-app item if this device made it
  (⚠️ product, criterion 30)
Step D-5 — Close
- Action: .deleted(message) → coordinator pops → list reloads and shows the toast
```

## Server sync

Contract: innerlamp-be `docs/specs/api/openapi.yaml` @ 5f4ca56, tag `Memorials` — `GET /v1/memorials`,
`POST /v1/memorials`, `PUT /v1/memorials/{id}`, `DELETE /v1/memorials/{id}` (all Bearer). Schemas
`Memorial` / `MemorialRequest` and the error codes live there; this spec does not copy them. iOS-only
mapping decisions:

- A server id is numeric; a new entry carries a local UUID until `POST` returns its id. Cached
  entries without a numeric id predate the API and are skipped.
- `PUT` replaces the whole entry: the form always sends every field, including the reminder settings
  and `add_to_os_reminder` (product Appendix B item 6).
- **Known year**: the entity's day/month(/leap) in its calendar is converted to a solar `death_date`
  on save (strict conversion for a lunar date — criterion 19) and back on load; the leap marker is
  recovered from `solarToLunar(...).isLeapMonth` (product Appendix B item 1). **Unknown year**: day,
  month and `death_leap_month` are sent as entered (planned: today the leap flag is always `false`).
- `reminder.timezone` = `TimeZone.current.identifier` (product Appendix B item 3; planned).
- `add_to_os_reminder` is sent `true` only with a reminder.
- `photo_url` is not decoded until the portrait lands (`TD-Memorial-002`).
- The server never computes the next anniversary and never sends notifications.

## Product vectors

The three product files are the only test data for BR-MEM-03…10. Running them on iOS:

- `Scripts/sync-product-vectors.sh` copies `../innerlamp-be/docs/product/memorial/rules/*.json` into
  `InnerLampTests/ProductVectors/memorial/` and writes the source commit sha and file hashes to
  `InnerLampTests/ProductVectors/memorial/SOURCE`. The copy is a pinned, script-refreshed mirror —
  never edited by hand; a mismatch is fixed in the backend repo (via `ba-writer`) and re-synced. A
  bundled copy is needed because XCTest runs on a device, which cannot read the sibling checkout.
- `ILMemorialProductVectorTests` loads every case from the test bundle:
  - `next-anniversary.json` → `nextAnniversary(for:now:)` with a gregorian calendar fixed to
    `Asia/Ho_Chi_Minh`, `now` = the case's `today` at noon; asserts `next_date`, `days_left`, `ordinal` (including `0`).
  - `anniversary-ordinal.json` → `ILMemorialFormatter.ordinalText`.
  - `death-date-conversion.json` → `ILLunarCalendar.solarToLunar` (day, month, year, leap) and the
    strict lunar → solar conversion (`valid: false` → `nil`).
- Expected failures today (they are the drift, not test bugs): ordinal `0` collapsed to `nil`; day 30
  of a 29-day month accepted; leap input not modelled.

## Deliberately stubbed for now

- Reminder scheduling and the Reminders-app sync: `scheduleReminders` / `cancelReminder` in
  `ILMemorialUseCaseImpl` are one-line `print("TODO …")` stubs (`TD-Memorial-001`); the settings are
  stored on the server so nothing needs migrating when they land.
- Portrait: initial-letter avatar only (`TD-Memorial-002`); the API has no photo route yet (backend
  `TD-001`, blocked on GCS).

## Known drift against product spec v1.0

Listed in `requirements.md` "Pending" with the criterion numbers; each has a `[ ]` task in `tasks.md`
Phase 6–7. In short: no leap month (BR-MEM-04), year menu 96 years (BR-MEM-03), lenient day-30
conversion for a date of death (BR-MEM-03), delete without confirmation (BR-MEM-12), reminders stub
(FR-MEM-008/009), guest sees an empty book (FR-MEM-001), sign-out keeps the cache, offline
never-loaded shows the empty state (FR-MEM-010), no length checks (FR-MEM-012/013), no
`reminder.timezone`, vectors not run (NFR-MEM-03).

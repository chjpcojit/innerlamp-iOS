# Design — Memorial

Version: 1.3
Last updated: 2026-10-07
Status: implemented (build-verified, tests not run) — server API + Core Data offline cache; reminders and portrait stubbed

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. One feature folder, two screens: the list
(`ILMemorial…`) and the add/edit form (`ILMemorialEdit…`), both owned by a single
`ILMemorialCoordinator` that is a child of `ILHomeCoordinator` (the entry is Home's week-strip
link, so it is not a cross-section flow and does not go through `AppCoordinator`). Data is
**local-first**: a repository protocol in Domain with a Core Data implementation now; a remote
data source is added when an API contract exists. Shape reference: `Festivals` (list + detail
navigation) for the coordinator, `Reminder` for the toggles/chips form.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILMemorialEntity.swift` | `ILMemorialEntity` (id, name, `ILMemorialRelationship`, `ILMemorialCalendarKind` lunar/solar, day, month, `deathYear: Int?`, note, `ILMemorialReminder?` {leadDays, time}, `syncToReminders`, `portraitFileName: String?`) and `ILMemorialNextAnniversary` (date, daysUntil, ordinal: Int?). Pure; Foundation only. |
| Domain / Repository protocol | `Domain/Repositories/ILMemorialRepository.swift` | `loadAll()`, `save(_:)`, `delete(id:)`, plus `ILMemorialError` (`loadFailed` / `saveFailed` / `deleteFailed`). |
| Domain / UseCase | `Domain/UseCases/Memorial/ILMemorialUseCase.swift` | `loadItems(now:)` (entries + next anniversary, soonest first, ties by name), `nextAnniversary(for:now:)` (rule in requirements; also carries the ordinal and the lunar equivalent), `makeNewEntry()`, `isValid(name:)`, `save` (trims the name), `delete`. Calendar maths is pure and unit-tested. Preview and label formatting live in the Presentation layer (`ILMemorialFormatter`). |
| Core util (shared) | `Core/Utils/ILLunarCalendar.swift` — modified: added `lunarToSolar(day:month:year:isLeap:)` and `SolarDate` | Inverse conversion for lunar entries; reuse `matchesLunarDay` for the day-30 / 29-day-month rule. |
| Data / Local | `Data/DataSources/Local/ILMemorialLocalDataSource.swift` + `ILMemorialMO.swift` | Core Data entity `ILMemorialMO` in the new model version `InnerLamp 4.xcdatamodel` (now current); maps to/from the Entity (`deathYear == 0` = unknown, `reminderLeadDays == -1` = reminders off). |
| Data / Remote | `Data/DataSources/Remote/Memorials*Endpoint.swift`, `MemorialCreate/Update/DeleteEndpoint.swift`, `Data/DTOs/ILMemorialDTO.swift`, `Mappers/ILMemorialMapper.swift` | One call per file; DTO <-> entity mapping incl. lunar/solar conversion. |
| Data / Repository impl | `Data/Repositories/ILMemorialRepositoryImpl.swift` | Server first; Core Data cache only as an offline read fallback. |
| Reminder scheduling | **Not built** — `scheduleReminders` / `cancelReminder` are one-line TODO stubs in `ILMemorialUseCaseImpl` | Will schedule / cancel / reschedule each entry's next reminder behind a protocol. ⚠️ mechanism not confirmed (see requirements Pending; `TD-Memorial-001`). |
| Presentation / Formatter | `Presentation/Scenes/Memorial/ILMemorialFormatter.swift` | Shared display strings (days label, eyebrow, ordinal, stored date, solar line, reminder line). |
| Presentation / State | `Presentation/Scenes/Memorial/ILMemorialStateModel.swift` | List state: subtitle, highlight card model, row models (days label, `isSoon`, "Có nhắc"), empty flag, banner text. |
| Presentation / State | `Presentation/Scenes/Memorial/ILMemorialEditStateModel.swift` | Form state: title, field values, `nameError`, chip selections, day/month/year option lists, preview lines, reminder expanded flag, `canDelete`, save label. |
| Presentation / ViewModel | `ILMemorialViewModel.swift`, `ILMemorialEditViewModel.swift` | `Input -> Output`; nav events `ILMemorialNavEvent` (`.back`, `.addEntry`, `.editEntry(ILMemorialEntity)` — the entity is passed so the form needs no async load) and `ILMemorialEditNavEvent` (`.back`, `.saved(message)`, `.deleted(message)`). |
| Presentation / Coordinator | `ILMemorialCoordinator.swift` | Pushes the list, pushes the form (add/edit), pops on save/delete and passes the banner message back to the list. |
| Presentation / ViewController | `ILMemorialViewController.swift`, `ILMemorialEditViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel`. |
| Presentation / Views | `Scenes/Memorial/Views/` | `ILMemorialHighlightCardView`, `ILMemorialRowView`, `ILMemorialChipGroupView`, `ILMemorialPreviewCardView`, `ILMemorialReminderCardView`. Reuses `ILNavBar`, `ILChip`/`ILChipFlowView`, `ILInputCardView`, `ILButton`, `ILStateView`, `ILAvatarView`. |
| Design system (new, generic) | `Common/DesignSystem/Components/` | `ILSegmentedToggleView` (Âm/Dương), `ILSwitchRowView`, `ILMenuFieldView` (day/month/year pull-down), `ILAlert.success` toast via `ILAlertPresenter` (save/delete confirmation, window level); icons `ILIcons.chevronDown` / `.checkmark`. |
| Home (modification) | `ILHomeWeekCalendarView.swift`, `ILHomeViewController.swift`, `ILHomeViewModel.swift` (`ILHomeNavEvent.openMemorial`), `ILHomeCoordinator.swift` (`showMemorial()`) | Add the "Sổ giỗ" link beside "Lịch âm". Specified in `Docs/Specs/Home/` v1.7. |
| DI | `App/DIContainer.swift` | `makeMemorialUseCase/Repository/ViewModel/Coordinator`. |
| Localization | `Resources/Localization/vi.json` | All copy under `memorial.*` keys. |
| Tests | `InnerLampTests/ILMemorialViewModelTests.swift`, `ILMemorialEditViewModelTests.swift`, `ILMemorialUseCaseTests.swift`, `ILLunarToSolarTests.swift` | Next-anniversary and ordinal rules, validation, save/delete messages, empty state. |

## Navigation flow

```
ILHomeCoordinator
  └─ .openMemorial → showMemorial() → ILMemorialCoordinator (child)
       push ILMemorialViewController                       (list)
       (Thêm / Thêm người thân)    → .addEntry        → push ILMemorialEditViewController (add)
       (highlight card / row tap)  → .editEntry(id)   → push ILMemorialEditViewController (edit)
       (form Lưu / Xóa)            → .saved / .deleted → pop, list refreshes + shows banner
       (Back)                      → .back            → finish() → Home
```

## Data flow

**List load**: `viewDidLoad` / returning from the form → `useCase.loadEntries(now:)` →
`repository.loadAll()` (Core Data) → `nextAnniversary` per entry → sort by `daysUntil` → map to
`ILMemorialStateModel` (labels and the soonest entry's highlight card are formatted in the
ViewModel, not the Entity).

**Save** (all local, no network):

```
Step 1 — Validate (form)
- Trigger: Save tapped
- Pre-condition: none
- Action: useCase.validate(name:) on the trimmed name
    - Failure (empty) → nameError shown, stop
Step 2 — Persist
- Action: repository.save(entry)  (Core Data insert/update by id)
    - Failure → ⚠️ Not confirmed: error copy for a Core Data save failure — blocks the
      failure-path test; shown via the shared error alert until decided
Step 3 — Reminder
- Pre-condition: entry.reminder != nil
- Action: reminder scheduler cancels the old request and schedules the next occurrence;
  if syncToReminders, also creates/updates the Reminders item
    - ⚠️ Not confirmed: mechanism, permission-denied behaviour, reschedule policy
      (see requirements Pending)
Step 4 — Close
- Action: .saved(message) → coordinator pops → list reloads and shows the banner
```

**Server sync** (contract: backend `docs/specs/api/openapi.yaml`, `/v1/memorials`; all calls need the
access token; envelope `{success, data}`):

```
List    GET    /v1/memorials          -> data.items[] (≤100, no pagination); replaces the Core Data cache
Create  POST   /v1/memorials          -> 201 Memorial; 409 MEMORIAL_LIMIT_REACHED at 100 entries
Update  PUT    /v1/memorials/{id}     -> 200 Memorial (replaces the whole entry); 404 MEMORIAL_NOT_FOUND
Delete  DELETE /v1/memorials/{id}     -> 200 {"success":true} (no data); 404 treated as already deleted
```

- Body fields: `full_name` (≤100), `relationship` (enum), `death_calendar` (`solar`/`lunar`), either
  `death_date` (solar `YYYY-MM-DD`, year known) or `death_day` + `death_month` + `death_leap_month`
  (year unknown), `note` (≤1000), `reminder {days_before 0–30, time "HH:mm"}`, `add_to_os_reminder`
  (only valid with a reminder). Unknown fields — including `id` — are rejected.
- Mapping lives in `ILMemorialMapper` (`AS-Memorial-005`); errors map to `ILMemorialError`
  (`offline`, `unauthorized`, `limitReached`, `notFound`, `invalidInput`). 400 `VALIDATION_ERROR`
  shows one generic message — per-field messages are not built.
- Server ids are numeric; a new entry carries a local UUID until `POST` returns its id.
- The server never computes the next giỗ or sends notifications: the app derives both locally.
- Source of truth = server; the cache is read only when offline (`AS-Memorial-006`).

## Deliberately stubbed for now

- Portrait: placeholder avatar (name initial) only; the prototype's "Chạm hoặc kéo ảnh chân dung vào" caption is not shown (`TD-Memorial-002`).
- Reminder scheduling and the Reminders sync: stubbed (`TD-Memorial-001`) until the mechanism is confirmed;
  the reminder fields are still stored on the entry so nothing needs migrating later.
- Portrait upload/display: the API has no photo route yet (`photo_url` is always null; backend `TD-001`, blocked on GCS).

# Design — Memorial

Version: 3.0
Last updated: 2026-10-14
Status: in-progress — list, form, server CRUD and offline cache built (build-verified, tests not run); planned: remove the local-reminder stubs and the Reminders-app option, FCM push (registration, permission, deep link), account time zone, leap month, strict date checks, delete confirmation, guest / sign-out / offline / server-error cases, product vectors

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MVVM-C + Clean Architecture per `AGENTS.md`. One feature folder, two screens: the list
(`ILMemorial…`) and the add/edit form (`ILMemorialEdit…`), both owned by `ILMemorialCoordinator`, a
child of `ILHomeCoordinator` (the entry is Home's week-strip link, not a cross-section flow). Opening a
memorial reminder (push or notification list) reaches the same coordinator through `AppCoordinator`.

How iOS meets the product constraints (product spec v2.1 §2.7, §3.6, ADR-0001, ADR-0002; see
`requirements.md`):

- **Server is the source of truth** (BR-MEM-01): `/v1/memorials` through `ILMemorialRepositoryImpl`;
  Core Data is a read copy used only when the server cannot answer (FR-MEM-010). The copy is stamped
  with the account it belongs to and deleted on every way a session ends.
- **Client computes for display** (BR-MEM-05…10): `ILMemorialUseCaseImpl.nextAnniversary` over
  `ILLunarCalendar` (Hồ Ngọc Đức's algorithm, UTC+7). Correctness is proven only by the client product
  vectors (row "Product vectors" below), not by restating rules here.
- **The server sends reminders** (ADR-0002): the app schedules nothing. The local-notification stubs
  and the Reminders-app option are removed. The app (a) saves the reminder settings, (b) reports the
  device time zone as the account time zone, (c) registers its FCM token so the server can push
  (ADR-0001), and (d) routes an opened memorial reminder to its entry.
- **Push is app-wide infrastructure.** Memorial is its first user, so the push pieces are specified here;
  they live under `Core/Push/` and are not memorial-specific (later producers: temple announcements,
  events). The notification list screen is `Docs/Specs/Notifications/`.

## Layers & components

| Layer | File | Responsibility | State |
|---|---|---|---|
| Domain / Entity | `Domain/Entities/ILMemorialEntity.swift` | `ILMemorialEntity` (id, name, `ILMemorialRelationship` ×10, `ILMemorialCalendarKind`, day, month, `deathYear: Int?` — a lunar year for a lunar entry, note, `ILMemorialReminder?` {leadDays, hour, minute}, `portraitFileName`), `ILMemorialNextAnniversary` (date, daysUntil, ordinal, lunar day/month of the date), `ILMemorialItem`. Foundation only. | built; **remove `syncToReminders`** (FR-MEM-009 removed); **add `isLeapMonth: Bool`** (BR-MEM-04); ordinal must keep `0` (vector) — the "< 1 → no label" rule moves to the formatter |
| Domain / Reminder choices | `Domain/Entities/ILMemorialEntity.swift` (`ILMemorialReminder`) | The BR-MEM-11 lead and time choices and `nearestChoice(...)` for a server value outside them (criterion 28). | planned; tie-break ⚠️ product |
| Domain / Repository protocol | `Domain/Repositories/ILMemorialRepository.swift` | `loadAll()`, `load(id:)`, `save(_:)`, `delete(id:)`; result of `loadAll` tells whether it came from the offline copy; `ILMemorialError` (`loadFailed`/`saveFailed`/`deleteFailed`/`offline`/`serverError`/`unauthorized`/`limitReached`/`invalidInput`/`notFound`/`noOfflineCopy`). | built; **add** `load(id:)` (deep link), an offline-copy flag, `serverError`, `noOfflineCopy` |
| Domain / UseCase | `Domain/UseCases/Memorial/ILMemorialUseCase.swift` | `loadItems(now:)` (entries + next anniversary, soonest first, ties by name), `loadItem(id:now:)`, `nextAnniversary(for:now:)`, `makeNewEntry()`, `validate(_:now:)`, `save` (trims name), `delete`. | built; **remove** `scheduleReminders` / `cancelReminder` stubs and their calls (`TD-Memorial-001`); **add** `validate` (name ≤ 100, note ≤ 1000, strict date / leap month exists / year ≥ 1900 / not after today — criteria 17–19), `loadItem(id:)` |
| Core util (shared) | `Core/Utils/ILLunarCalendar.swift` | `solarToLunar` (returns `isLeapMonth`), `lunarToSolar(day:month:year:isLeap:)` — resolves day 30 to 29 in a short month (right for BR-MEM-06). | built; **add a strict variant** that returns `nil` for day 30 in a 29-day month or a leap month the year lacks, used only for a date of death (BR-MEM-03/04) |
| Data / Local | `Data/DataSources/Local/ILMemorialLocalDataSource.swift` + `ILMemorialMO.swift` (model `InnerLamp 4.xcdatamodel`) | Core Data offline copy: `fetchAll`, `upsert`, `delete`, `replaceAll`. `deathYear == 0` = unknown, `reminderLeadDays == -1` = off. | built; **new model version**: add `isLeapMonth`, `ownerAccountID`; drop `syncToReminders`; `fetchAll(ownerAccountID:)` |
| Data / Remote | `Data/DataSources/Remote/MemorialsListEndpoint.swift`, `MemorialCreateEndpoint.swift`, `MemorialUpdateEndpoint.swift`, `MemorialDeleteEndpoint.swift`, `MemorialGetEndpoint.swift` | One operation per file (cited below). | built; **add** `MemorialGetEndpoint` (`GET /v1/memorials/{id}`) |
| Data / DTO + Mapper | `Data/DTOs/ILMemorialDTO.swift`, `Data/DTOs/Mappers/ILMemorialMapper.swift` | Wire ↔ entity, incl. lunar ↔ solar conversion of a known-year date (see "Server sync"). | built; **change**: stop sending `add_to_os_reminder` (and ignore it on decode); never send `reminder.timezone`; send `death_leap_month` when the year is unknown; recover `isLeapMonth` from `solarToLunar` when known; strict conversion |
| Data / Repository impl | `Data/Repositories/ILMemorialRepositoryImpl.swift` | Server first; offline copy on any non-401 load failure (offline, timeout, 5xx), only for the signed-in account; best-effort copy writes after a successful write; 404 on PUT/DELETE removes the entry from the copy. | built; **change**: fall back on server errors too, filter by account, report "from offline copy" / `noOfflineCopy`, map 5xx to `serverError` |
| Core / Session cleanup | `Data/Repositories/ILSessionDataCleanerImpl.swift` (via `ILProfileUseCase.logout`), `App/AppCoordinator.swift` (`handleSessionExpired`) | Deletes user-scoped Core Data rows, `ILMemorialMO` included. | built for the Me-tab sign-out; **add** the same cleanup on session expiry (criterion 3) |
| Core / Push (app-wide, planned) | `Core/Push/ILPushService.swift` (+ `AppDelegate` hooks) | FirebaseMessaging setup, `MessagingDelegate` (token changes), `UNUserNotificationCenterDelegate` (foreground banner, open → route), `registerForRemoteNotifications`. Logs no token and no payload text. | planned — blocked on the Firebase project + config |
| Core / Push permission (planned) | `Domain/Repositories/ILNotificationPermission.swift` + `Data/Services/ILNotificationPermissionImpl.swift` | `status()` (notDetermined / denied / allowed) and `request()` over `UNUserNotificationCenter`, so ViewModels stay Foundation-only; `openSettingsURL` for "Mở Cài đặt". | planned |
| Core / Push registration (planned) | `Domain/Repositories/ILPushRegistrationRepository.swift` + `Data/Repositories/ILPushRegistrationRepositoryImpl.swift` + endpoints | `register(token:)` / `unregister()` against the backend. | planned — ⚠️ contract (product Appendix B item 8) |
| Core / Account time zone (planned) | `Domain/Repositories/ILAccountTimeZoneRepository.swift` + `Data/Repositories/ILAccountTimeZoneRepositoryImpl.swift` + endpoint, `Core/Push/ILAccountTimeZoneReporter.swift` | Reports `TimeZone.current.identifier` on sign-in, app active, `NSSystemTimeZoneDidChange`. | planned — ⚠️ contract (product Appendix B item 3) |
| App / Deep link (planned) | `App/AppCoordinator.swift`, `ILMainTabCoordinator`, `ILHomeCoordinator.showMemorial(entryID:)`, `ILMemorialCoordinator.showEntry(id:)`, `Core/Push/ILPushRoute.swift` | Parses a memorial reminder (push payload or notification-list item) into `.memorialEntry(id)` and opens Home → book → form. | planned — payload keys ⚠️ contract (product Appendix B item 7) |
| Notifications feature (dependency) | `Presentation/Scenes/Notifications/` — `Docs/Specs/Notifications/` | Shows the list; a memorial item hands `.memorialEntry(id)` to the route above. | mock today; real list blocked on its own contract |
| Presentation / Formatter | `Presentation/Scenes/Memorial/ILMemorialFormatter.swift` | Days label, eyebrow, ordinal label (BR-MEM-09 label table), stored date line, solar line, reminder line. | built; **remove** the "có trong Lời nhắc" suffix; **add** leap marker ("10/6 nhuận"); ordinal `≤ 0` → no label |
| Presentation / State | `ILMemorialStateModel.swift`, `ILMemorialEditStateModel.swift` | List: subtitle, highlight, rows, empty flag, banner. Form: option lists, `nameError`, preview lines, reminder options, `canDelete`, `isSaving`. | built; **remove** `syncOn`; **add** list offline-copy line / no-copy / sign-in states, form `noteError` / `dateError`, `isLeapMonth`, `showsLeapSwitch`, `showsPushHint` |
| Presentation / ViewModel | `ILMemorialViewModel.swift`, `ILMemorialEditViewModel.swift` | `Input -> Output`; nav events `ILMemorialNavEvent` (`.back`, `.addEntry`, `.editEntry(entity)`, `.openFamilyTree`) and `ILMemorialEditNavEvent` (`.back`, `.saved(message)`, `.deleted(message)`). | built; **remove** `syncToggled` input and the Reminders-app saved message; **change**: year options 1900…current year; delete via confirm step; `.notFound` on save/delete → `.removed(message)`; load errors no longer collapse to empty; **add** `.signInRequired`, permission prompt trigger (criterion 31), push hint + `openSettings` input (criterion 29) |
| Presentation / Coordinator | `ILMemorialCoordinator.swift` | Pushes list and form; pops on save/delete and hands the message to the list. | built; **add** `.removed` → pop + reload + message, routing to sign-in for a guest, `showEntry(id:)` |
| Presentation / ViewController | `ILMemorialViewController.swift`, `ILMemorialEditViewController.swift` | `setupViews` / `setupConstraints` / `bindViewModel`. | built; **add** delete confirmation action sheet, leap switch, offline-copy line, no-copy state |
| Presentation / Views | `Scenes/Memorial/Views/` | `ILMemorialHighlightCardView`, `ILMemorialRowView`, `ILMemorialChipGroupView`, `ILMemorialPreviewCardView`, `ILMemorialReminderCardView`, `ILMemorialEmptyView`; reuses `ILNavBar`, `ILChip`/`ILChipFlowView`, `ILInputCardView`, `ILButton`, `ILStateView`, `ILAvatarView`. | built; **remove** the Reminders-app `syncRow` from `ILMemorialReminderCardView` and the "Lấy từ gia phả" `treeCard` from `ILMemorialEmptyView`; **add** the push hint + "Mở Cài đặt" row to the reminder card |
| Design system | `Common/DesignSystem/Components/` | `ILSegmentedToggleView`, `ILSwitchRowView`, `ILMenuFieldView`, `ILAlert.success` toast via `ILAlertPresenter`; icons `chevronDown` / `checkmark`. | built |
| Home (modification) | `ILHomeWeekCalendarView.swift`, `ILHomeViewController.swift`, `ILHomeViewModel.swift` (`.openMemorial`), `ILHomeCoordinator.swift` (`showMemorial()`) | The "Sổ giỗ" link — `Docs/Specs/Home/` v1.7. | built; **add** `showMemorial(entryID:)` for the deep link |
| Sign-out hook | `ILProfileUseCase.logout` | Before revoking: `ILPushRegistrationRepository.unregister()` (best effort), FCM `deleteToken`; after: session cleanup (memorial copy included), `removeAllDeliveredNotifications` (criteria 3–4). | partly built (cleanup); push steps planned |
| App configuration (planned) | `InnerLamp.entitlements`, `Info.plist`, SPM, `GoogleService-Info.plist` per environment | Push Notifications capability (`aps-environment`), `firebase-ios-sdk` (FirebaseMessaging only), `FirebaseAppDelegateProxyEnabled = NO` (explicit hooks), one Firebase config per environment. | planned — blocked on the Firebase project (owner) |
| DI | `App/DIContainer.swift` | `makeMemorialUseCase/Repository/ViewModel/EditViewModel/Coordinator`, `memorialLocalDataSource`. | built; **add** push service, permission, registration, time-zone repositories |
| Localization | `Resources/Localization/vi.json` | All copy under `memorial.*`; §3.1.1 is the copy source. | built; **remove** `memorial.edit.sync.*`, `memorial.reminder.inReminders`, `memorial.message.savedWithReminder`, `memorial.empty.fromTree.*`; **add / update** the §3.1.1 keys (leap, too long, date cases, confirm delete, could not save, connection needed, offline line, no copy, no longer in book, push hint, "Mở Cài đặt"); update the book-full text |
| Tests | `InnerLampTests/ILMemorialUseCaseTests.swift`, `ILMemorialViewModelTests.swift`, `ILMemorialEditViewModelTests.swift`, `ILMemorialMapperTests.swift`, `ILMemorialRepositoryTests.swift`, `ILMemorialTestSupport.swift`, `ILLunarToSolarTests.swift` | Use case, ViewModels, mapper, repository (success, offline, 401, 409, 400, 404). Written, build-verified, not run. | built; **update** for removed `syncToReminders`, new fallbacks, 404 handling |
| Product vectors (planned) | `InnerLampTests/ILMemorialProductVectorTests.swift` + `InnerLampTests/ProductVectors/memorial/*.json` + `Scripts/sync-product-vectors.sh` | Runs every case of the three client product files (criterion 41). See "Product vectors". | planned |

## Navigation flow

```
ILHomeCoordinator
  └─ .openMemorial → showMemorial() → ILMemorialCoordinator (child)
       push ILMemorialViewController                         (list)
       guest / 401 on load          → .signInRequired   → sign-in prompt (planned)
       (Thêm người thân)            → .addEntry          → push ILMemorialEditViewController (add)
       (highlight card / row tap)   → .editEntry(entity) → push ILMemorialEditViewController (edit)
       (Xem gia phả, non-empty list)→ .openFamilyTree    → child ILFamilyTreeCoordinator
       (form Lưu ok / Xóa confirmed)→ .saved / .deleted  → pop, list reloads + toast
       (form Lưu / Xóa → 404)       → .removed(message)  → pop, list reloads + message (planned)
       (Back)                       → .back              → finish() → Home

AppCoordinator (planned deep link)
  push opened / notification-list memorial item → ILPushRoute .memorialEntry(id)
       no session        → Login (nothing shown)
       session           → main tab Home → ILHomeCoordinator.showMemorial(entryID:)
                           → list pushed, then showEntry(id:) → form (edit) or list + "no longer" message
```

## Step-by-step Flow

### Load the book (list `viewDidLoad`, return from the form)

```
Step L-1 — Session check (planned)
- Trigger: list appears
- Pre-condition: none
- Action: no access token (guest preview) → .signInRequired, stop (criterion 2). Nothing is read
  from the offline copy.
Step L-2 — Fetch
- Action: GET /v1/memorials (MemorialsListEndpoint)
    - Success → Step L-3
    - offline / timeout / 5xx / other non-401 → offline copy of the signed-in account non-empty: use
      it with the offline-copy line, go to Step L-4 (criterion 36); none: "Chưa tải được sổ giỗ…" with
      retry, stop (criterion 37) — planned (today: offline only, no line, empty state otherwise)
    - 401 → sign-in prompt (planned), offline copy not shown
Step L-3 — Refresh the offline copy
- Action: localDataSource.replaceAll(entries, ownerAccountID:) — best effort, a failure is logged
  and ignored
Step L-4 — Compute and show
- Action: nextAnniversary per entry → sort (daysUntil, then name) → ILMemorialStateModel
Step L-5 — Permission prompt (planned, platform)
- Action: notification permission notDetermined and some entry has a reminder on → request once
  (criterion 31). No reminder is scheduled on the device.
```

### Save (form "Lưu")

```
Step S-1 — Validate locally
- Trigger: Save tapped, not already saving
- Action: useCase.isValid(name:) today; planned useCase.validate(entry, now): name ≤ 100,
  note ≤ 1000, and — when the year is known — strict conversion (no day-30 fallback, the leap month
  must exist that year), year ≥ 1900, date ≤ today (criteria 17–19)
    - Failure → field error with the §3.1.1 copy, nothing sent, stop
Step S-2 — Map
- Action: ILMemorialMapper.toRequest(entry) (see "Server sync"; no add_to_os_reminder, no timezone)
Step S-3 — Write
- Action: numeric id → PUT /v1/memorials/{id}; local UUID → POST /v1/memorials
    - offline → "Cần kết nối mạng để thay đổi sổ giỗ.", form stays, stop
    - 404 (PUT) → localDataSource.delete(id:), .removed("Mục này không còn trong sổ giỗ."), stop
      (criterion 23, planned)
    - other failure → mapped ILMemorialError → alert per the requirements' Error → UI table, stop
Step S-4 — Offline copy
- Action: localDataSource.upsert(saved) — best effort
Step S-5 — Permission prompt (planned, platform)
- Action: reminder on and permission notDetermined → request once (criterion 31)
Step S-6 — Close
- Action: .saved("Đã lưu vào sổ giỗ.") → coordinator pops → list reloads (Load flow) and shows
  the toast. The server re-plans the reminder (ADR-0002); nothing is scheduled here.
```

### Delete (form "Xóa khỏi sổ giỗ", edit mode only)

```
Step D-1 — Confirm (planned; today the delete starts immediately)
- Trigger: delete tapped
- Action: action sheet "Xóa {tên} khỏi sổ giỗ?" / "Không thể khôi phục sau khi xóa." with "Xóa"
  (destructive) and "Hủy" (criterion 24)
    - Hủy → nothing changes, stop
Step D-2 — Delete
- Action: DELETE /v1/memorials/{id} (MemorialDeleteEndpoint)
    - 404 → Step D-3, then .removed("Mục này không còn trong sổ giỗ.") (criterion 26, planned;
      today reported as deleted)
    - offline → "Cần kết nối mạng để thay đổi sổ giỗ.", form stays, stop
    - other failure → alert, form stays usable, stop
Step D-3 — Offline copy
- Action: localDataSource.delete(id:) — best effort
Step D-4 — Close
- Action: .deleted("Đã xóa {tên} khỏi sổ giỗ.") → coordinator pops → list reloads and shows the
  toast. The server stops the entry's reminders (ADR-0002); nothing is cancelled here.
```

### Sign-in and app start: push registration and account time zone (planned)

```
Step P-1 — Sign in (Login feature, out of this feature's scope)
- Trigger: login succeeds, or the app starts with a stored session (Splash)
- API: POST /v1/auth/login — owned by Docs/Specs/Login/
Step P-2 — Get the push token
- Pre-condition: signed in; Firebase configured (blocked on the Firebase project)
- Action: registerForRemoteNotifications → APNs token handed to FirebaseMessaging → FCM token
  (available whether or not the user allowed alerts)
Step P-3 — Register the token
- Trigger: Step P-2 done, or MessagingDelegate reports a new token while signed in (criterion 30)
- API: ⚠️ Not confirmed (contract): register-push-token operation (product Appendix B item 8)
    - Success → done
    - Failure → logged without the token; retried at the next trigger
Step P-4 — Report the account time zone
- Trigger: sign-in, app becomes active with a session, NSSystemTimeZoneDidChange (criterion 34)
- API: ⚠️ Not confirmed (contract): account time-zone operation (product Appendix B item 3);
  value TimeZone.current.identifier
    - Failure → logged; retried at the next trigger
```

### Sign-out (Me tab; planned additions to `ILProfileUseCase.logout`)

```
Step O-1 — Remove the push registration
- Pre-condition: access token still present (must run before the revoke)
- API: ⚠️ Not confirmed (contract): delete-push-token operation (product Appendix B item 8) —
  best effort, a failure does not block sign-out
Step O-2 — Invalidate the FCM token
- Action: Messaging.messaging().deleteToken — so pushes stop even if Step O-1 failed (the server
  gets UNREGISTERED from FCM and prunes the token, ADR-0001)
Step O-3 — Revoke the session (built)
- API: POST /v1/auth/logout
Step O-4 — Clear local data (built for memorial) and delivered notifications (planned)
- Action: Keychain tokens, ILSessionDataCleanerImpl (ILMemorialMO included),
  UNUserNotificationCenter.removeAllDeliveredNotifications (criteria 3–4)
Session expiry (AppCoordinator.handleSessionExpired) runs O-2 and O-4 (no access token is left for
O-1 / O-3) — planned.
```

### Open a memorial reminder (push or notification list, planned)

```
Step N-1 — Route
- Trigger: user opens a memorial push (UNUserNotificationCenterDelegate didReceive) or a memorial
  item in the notification list (Docs/Specs/Notifications/)
- Action: ILPushRoute parses the memorial id — ⚠️ Not confirmed (contract): payload / list-item keys
  (product Appendix B item 7)
    - no session → Login, nothing shown, stop (criterion 33)
Step N-2 — Navigate
- Action: AppCoordinator → main tab Home → ILHomeCoordinator.showMemorial(entryID:) → list pushed
  (Load flow runs) → ILMemorialCoordinator.showEntry(id:)
Step N-3 — Load the entry
- API: GET /v1/memorials/{id} (MemorialGetEndpoint)
    - Success → push the form in edit mode with the entity
    - 404 → stay on the list, show "Mục này không còn trong sổ giỗ.", remove it from the copy
    - offline / 5xx → open from the offline copy when the entry is there, else stay on the list
      (its offline-copy state applies)
```

## Server sync

Contract: innerlamp-be `docs/specs/api/openapi.yaml` @ bf23f8b (memorial operations unchanged since
5f4ca56), tag `Memorials` — `GET /v1/memorials`, `POST /v1/memorials`, `GET /v1/memorials/{id}`,
`PUT /v1/memorials/{id}`, `DELETE /v1/memorials/{id}` (all Bearer). Schemas `Memorial` /
`MemorialRequest` and the error codes live there; this spec does not copy them. iOS-only mapping
decisions:

- A server id is numeric; a new entry carries a local UUID until `POST` returns its id. Cached
  entries without a numeric id predate the API and are skipped.
- `PUT` replaces the whole entry: the form always sends every field it owns, including the reminder
  settings.
- **Known year**: the entity's day/month(/leap) in its calendar is converted to a solar `death_date`
  on save (strict conversion for a lunar date — criterion 19) and back on load; the leap marker is
  recovered from `solarToLunar(...).isLeapMonth` (product Appendix B item 1). **Unknown year**: day,
  month and `death_leap_month` are sent as entered (planned: today the leap flag is always `false`).
- `reminder.timezone` is never sent (account time zone instead, criteria 34–35); the server's default
  applies until the backend retires the field.
- `add_to_os_reminder` is no longer sent (the contract makes it optional, default `false`) and is
  ignored on decode. Sending it is stopped **before** the backend removes it from the contract, because
  the contract rejects unknown fields with 400.
- `photo_url` is not decoded until the portrait lands (`TD-Memorial-002`).
- The server computes the next anniversary for reminders and sends them (ADR-0002); the app computes
  it only for display.

## Product vectors

The three client product files are the only test data for BR-MEM-03…10 on iOS (`reminder-moment.json`
is backend-only, product §4.3). Running them on iOS:

- `Scripts/sync-product-vectors.sh` copies `../innerlamp-be/docs/product/memorial/rules/{next-anniversary,anniversary-ordinal,death-date-conversion}.json`
  into `InnerLampTests/ProductVectors/memorial/` and writes the source commit sha and file hashes to
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

- Local reminder scheduling: `scheduleReminders` / `cancelReminder` in `ILMemorialUseCaseImpl` are
  one-line `print("TODO …")` stubs (`TD-Memorial-001`). They are **removed**, not built (ADR-0002); no
  local notification was ever scheduled, so nothing needs cleaning up on devices.
- Push, account time zone and the deep link wait for their contract operations (⚠️ above) and the
  Firebase project; until then the memorial book works without reminders on iOS.
- Portrait: initial-letter avatar only (`TD-Memorial-002`); the API has no photo route yet (backend
  `TD-001`, blocked on GCS).

## Known drift against product spec v2.1

Listed in `requirements.md` "Pending" with the criterion numbers; each has a `[ ]` task in `tasks.md`
Phase 6–8. In short: Reminders-app option still present and `add_to_os_reminder` sent (FR-MEM-009
removed); no push, no time-zone report (FR-MEM-008, BR-MEM-11); empty state offers "Lấy từ gia phả"
(FR-MEM-002); no leap month (BR-MEM-04); year menu 96 years and lenient day-30 conversion (BR-MEM-03);
delete without confirmation (BR-MEM-12); guest sees an empty book (FR-MEM-001); offline copy not tied
to the account, kept after session expiry, not used on server errors, no offline line (FR-MEM-010);
404 handling on save/delete (FR-MEM-004/005); no length checks (FR-MEM-012/013); copy differs from
§3.1.1; vectors not run (NFR-MEM-03).

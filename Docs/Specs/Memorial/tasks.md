# Tasks — Memorial

Version: 3.9
Last updated: 2026-11-17
Status: Phase 1–9 built for the P4 integration; Phase 10 (push + server reminders) and the photo E2E remain blocked on the backend. `xcodebuild build` + `build-for-testing` (generic iOS) green on 2026-11-17; unit tests compile-only (no simulator, per the owner). QA v1 scope: 15 PASS, 1 FAIL (AC-8, fixed 2026-11-17), 54 NOT RUN, 31 BLOCKED (screenshot evidence).

> See `changelog.md` in this folder for the version history of this spec.

Every item traces to a row of `design.md` "Layers & components" or a step of its Step-by-step Flow.
`[x]` only where the code was read and does what the product spec v2.1 now requires.

Process: a code task is ticked in the same change that lands the code and a green build gate
(`xcodebuild build` + `build-for-testing`, generic iOS). An item whose code is done but whose test or
device step has not run stays `[ ]` with the real reason (`compile-only`, `[NOT RUN]`, `[DEFERRED]`).

## Phase 1 — UI

- [x] `ILMemorialViewController` on `BaseViewController` (list: nav bar, highlight card, "THEO NGÀY GIỖ SẮP TỚI" rows, empty state `ILMemorialEmptyView`, sticky "Thêm người thân"; toast via `ILAlert.success`; the "Xem gia phả" button was removed on 2026-11-17, AC-8)
- [x] `ILMemorialEditViewController` (portrait placeholder, name + error, relationship chips, calendar toggle, day/month/year menus, preview card, note, reminder card, Save/Delete)
- [x] Feature views under `Scenes/Memorial/Views/` and the generic design-system pieces (`ILSegmentedToggleView`, `ILSwitchRowView`, `ILMenuFieldView`)
- [ ] Visual QA against the prototype (`gio`, `gioEmpty`, `gioEdit`) on device, light + dark, long names, Dynamic Type [NOT RUN] needs physical device

## Phase 2 — Domain + Presentation logic

- [x] `ILLunarCalendar.lunarToSolar(day:month:year:isLeap:)` (day 30 → 29 in a short month, BR-MEM-06) + `ILLunarToSolarTests`
- [x] `ILMemorialEntity` (+ `ILMemorialRelationship`, `ILMemorialCalendarKind`, `ILMemorialReminder`, `ILMemorialNextAnniversary`, `ILMemorialItem`)
- [x] `ILMemorialRepository` protocol + `ILMemorialError`
- [x] `ILMemorialUseCaseImpl`: `loadItems` (sort soonest, ties by name), `nextAnniversary` (lunar regular month in lunar years −1/0/+1, solar month-end clamp), `makeNewEntry` (FR-MEM-003 defaults), `isValid(name:)`, `save` (trims), `delete`
- [x] `ILMemorialFormatter` (days label, eyebrow, ordinal label, stored date, solar line, reminder line)
- [x] `ILMemorialStateModel`, `ILMemorialEditStateModel` (no UIKit)
- [x] `ILMemorialViewModel` + `ILMemorialEditViewModel` (`Input -> Output`, nav events, empty-name error cleared on typing, preview recomputed on every change, lead/time fixed choices of BR-MEM-11)
- [x] Me-tab sign-out deletes the memorial offline copy (`ILSessionDataCleanerImpl` includes `ILMemorialMO`, called from `ILProfileUseCase.logout`)
- [x] `ILMemorialCoordinator` (pop + toast hand-off), `DIContainer.makeMemorial…`, `ILHomeCoordinator.showMemorial()` (Home v1.7)
- [x] Unit tests written and build-verified, not run (XCTest needs a device): `ILMemorialUseCaseTests`, `ILMemorialViewModelTests`, `ILMemorialEditViewModelTests`

## Phase 3 — Localization

- [x] `memorial.*` keys in `vi.json` for all v1.3 copy (no hardcoded text)
- [ ] Align copy with product §3.1.1 (book-full text, could not save, connection needed, offline line, no copy, no longer in book) and remove the keys of Phase 7 [DEFERRED] Phase 6 copy

## Phase 4 — API integration

- [x] Contract `/v1/memorials` (innerlamp-be `openapi.yaml`)
- [x] `ILMemorialDTO` + `ILMemorialMapper` (relationship enum, known-year lunar ↔ solar, unknown-year day/month)
- [x] Endpoint conformances (list / create / update / delete)
- [x] Server-first `ILMemorialRepositoryImpl` with the Core Data offline cache (`replaceAll`, `upsert`, `delete`); DELETE 404 = success
- [x] Mapper and repository tests (success, offline, 401, 409, 400, 404) — written, build-verified, not run
- [x] Solar day menu limited per month (Feb 29) so the server never sees 31 April
- [x] Offline save/delete refused with a message (FR-MEM-010) — text changes to §3.1.1 in Phase 6
- [x] 100-entry limit message on 409 `MEMORIAL_LIMIT_REACHED` (BR-MEM-02) — text changes to §3.1.1 in Phase 3
- [x] Network logging records method, path, status and timing only — no names or notes (NFR-MEM-02, verified in `NetworkService`)
- [ ] Manual test against the backend (`make run`, `:8080`) on a physical device [NOT RUN] needs device + BE

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Memorial/README.md` created
- [ ] Refresh that README — the Data rows still say model `InnerLamp 4` and "DTO N/A" (`README.md:24-25`), and it predates local reminders; describe the current v4 data path and the drift [DEFERRED] README Data rows stale
- [x] `Docs/Assumptions/Memorial/AS-Memorial-001…006` deleted (product spec supersedes them; anh Đức chose deletion over `Invalidated`, 2026-10-14); `@ai: assumption` markers in code now cite the product IDs
- [ ] Update `Docs/Tech-Debt/Memorial/TD-Memorial-001` → `Won't Fix` / close it: the stubs are gone and D1 local scheduling is live, but the entry is still `Open` (`TD-Memorial-001-reminders-not-built.md:7`) [DEFERRED] TD still Open
- [ ] `Docs/Knowledge/features/memorial.md` (OKF) — after Phase 6–8 are verified end to end (`Docs/Specs/OKF.md`) [DEFERRED] pending Phase 6–8

## Phase 6 — Product spec v2.1 alignment (drift)

- [x] **Product vectors** (criterion 41, NFR-MEM-03, BR-MEM-03…10): `Scripts/sync-product-vectors.sh` + `ILMemorialProductVectorTests` read the three JSON files in `InnerLampTests/Fixtures` (`next-anniversary`, `anniversary-ordinal`, `death-date-conversion`; `reminder-moment.json` is backend-only), never hand-edited — compile-only, tests not run (no simulator) [2026-11-17]
- [ ] Product vectors — record the source commit sha + file hashes in `SOURCE`; the script copies but writes no provenance [DEFERRED] missing SOURCE sha
- [x] Ordinal: `nextAnniversary` returns the raw ordinal (keep `0`); `ILMemorialFormatter.ordinalText` shows no label for `≤ 0` (BR-MEM-09, vector "died today")
- [x] Leap-month data path (BR-MEM-04, criteria 6, 13): `deathLeapMonth` on `ILMemorialEntity:52` and model `InnerLamp 7.xcdatamodel`; "Tháng nhuận" switch only for a year-less "Âm lịch" date (`ILMemorialEditViewController:88,343`; `ILMemorialEditViewModel:163,397`); request sends `death_leap_month` (`ILMemorialMapper.swift:56`) and a known year recovers the flag from `solarToLunar` (`:121`), save converts with `lunarToSolarExact` (`:70`) — compile-only [2026-11-17]
- [ ] Leap month in display: "10/6 nhuận" in the stored date line / highlight / preview — `ILMemorialFormatter.storedDateLine` (`:46`) ignores the flag [DEFERRED] leap label missing
- [ ] Strict date of death (BR-MEM-03, BR-MEM-04, criterion 19): strict `lunarToSolar` variant (day 30 in a 29-day month → `nil`, missing leap month → `nil`); use case `validate` rejects it, a date after today and a year < 1900 before any network call; `dateError` on the form with the four §3.1.1 messages [DEFERRED] validate missing
- [ ] Year menu 1900 → current year (BR-MEM-03, criterion 15); update `test_yearOptions_…NinetySixYears` [DEFERRED] 96-year menu
- [ ] Name ≤ 100 / note ≤ 1000 checked locally with the §3.1.1 field errors (FR-MEM-012, FR-MEM-013, criterion 18) [DEFERRED] length checks missing
- [x] Delete confirmation action sheet with the §3.1.1 copy before `DELETE` (BR-MEM-12, FR-MEM-005, criterion 24): `ILMemorialEditViewController.swift:190,383` with `memorial.delete.title` / `memorial.delete.message` — no UI test (not requested) [2026-11-17]
- [ ] Remove the stale BR-MEM-12 drift comment (`ILMemorialEditViewModel.swift:277`) and add confirm/cancel coverage [DEFERRED] drift comment + tests
- [x] Empty state without the "Lấy từ gia phả" card (FR-MEM-002, criterion 8): remove `treeCard` / `onFamilyTreeTap` from `ILMemorialEmptyView` and the `memorial.empty.fromTree.*` keys
- [ ] No "Xem gia phả" button under a non-empty list (FR-MEM-002, criterion 8): button, `.openFamilyTree` route and input removed on 2026-11-17 (`ILMemorialViewController`, `ILMemorialViewModel:9`, `ILMemorialCoordinator:41`); only the unused `memorial.list.familyTree` key remains (`vi.json:1650`) [DEFERRED] unused key remains
- [ ] Guest (FR-MEM-001, criterion 2): no token → `.signInRequired`, no server call, no offline-copy read; 401 on load → sign-in prompt instead of the empty state [DEFERRED] guest guard missing
- [x] Offline copy per account (FR-MEM-010, BR-MEM-01, criterion 39): `ownerAccountID` on `ILMemorialMO:39`, every read/write filtered in `ILMemorialLocalDataSource`, another account's cache invisible (`ILMemorialAccountScopeTests`) — compile-only [2026-11-17]
- [ ] Session-expiry cleanup (criteria 3, 39): `AppCoordinator.handleSessionExpired` (`:37-48`) deletes only the user row and cancels reminders, not the memorial cache [DEFERRED] expiry cleanup missing
- [ ] Offline copy on server failure (FR-MEM-010, criteria 36–37): fall back on offline / timeout / 5xx / any non-401 failure; offline-copy line "Đang hiện sổ giỗ đã tải lần trước. Không kết nối được máy chủ."; no copy → "Chưa tải được sổ giỗ. Vui lòng kết nối mạng và thử lại." with retry instead of the empty state; repository tests for 5xx with and without a copy [DEFERRED] offline-only fallback
- [ ] Write errors (FR-MEM-010, FR-MEM-003, criterion 38): offline → "Cần kết nối mạng để thay đổi sổ giỗ."; 5xx → "Chưa lưu được. Vui lòng thử lại." [DEFERRED] error copy stale
- [ ] Entry deleted elsewhere (FR-MEM-004, FR-MEM-005, criteria 23, 26): 404 on PUT and on DELETE → remove from the offline copy, `.removed("Mục này không còn trong sổ giỗ.")`, pop, reload; tests for both [DEFERRED] 404 handling missing
- [ ] Nearest reminder choice (FR-MEM-007, criterion 28): display-nearest exists (`ILMemorialEditViewModel:315,322,387`), but Save still sends the stored out-of-range value because only an explicit option tap writes the draft — tie-break blocked on ⚠️ product [DEFERRED] save keeps stored value
- [ ] Measure NFR-MEM-01 (100 entries, 4G, ≤ 2 s) on device (criterion 43) [NOT RUN] needs physical device

## Phase 7 — Remove local reminders and the Reminders-app option (ADR-0002, FR-MEM-009 removed)

- [x] Delete `scheduleReminders(for:)` / `cancelReminder(forEntryID:)` and their calls in `ILMemorialUseCaseImpl` (`loadItems`, `save`, `delete`) and the FR-MEM-008 "to be removed" comment; update `ILMemorialUseCaseTests`
- [x] Remove `syncToReminders` from `ILMemorialEntity`, `makeNewEntry`, `ILMemorialMapper`, `ILMemorialLocalDataSource`, `ILMemorialMO` (new model version, shared with Phase 6), and its tests
- [x] Stop sending `add_to_os_reminder` (drop it from `ILMemorialRequestDTO`; ignore it in `ILMemorialDTO`) — must ship before the backend removes the field (criterion 35); mapper test asserts neither `add_to_os_reminder` nor `reminder.timezone` is encoded
- [x] Remove the "Thêm vào Lời nhắc (Reminders)" row (`syncRow`, `onSyncToggled`) from `ILMemorialReminderCardView`, `syncToggled` input and the Reminders-app saved message from `ILMemorialEditViewModel`, `syncOn` from `ILMemorialEditStateModel`, the "có trong Lời nhắc" suffix from `ILMemorialFormatter` (criteria 6, 20, 27)
- [ ] Remove the unused Reminders-app keys from `vi.json`: `memorial.edit.sync.*` are gone, but `memorial.reminder.inReminders` (`:257`) and `memorial.message.savedWithReminder` (`:301`) remain [DEFERRED] 2 keys still in vi.json
- [x] Update `ILMemorialEditViewModelTests` / formatter tests: save always reports "Đã lưu vào sổ giỗ."

## Phase 8 — Push and account time zone (FR-MEM-008, BR-MEM-11, ADR-0001) — blocked on ⚠️ contract and the Firebase project

- [ ] App configuration: Push Notifications capability (`aps-environment`), `firebase-ios-sdk` (FirebaseMessaging) via SPM, `GoogleService-Info.plist` per environment, `FirebaseAppDelegateProxyEnabled = NO` — blocked on the Firebase project and APNs key (owner) [DEFERRED] Firebase/APNs pending
- [ ] `ILPushService` in `Core/Push/` + `AppDelegate` hooks: Firebase start, `registerForRemoteNotifications`, APNs token → Messaging, `MessagingDelegate` token changes, foreground banner; no token or payload text in logs (criteria 30, 32, 42) [DEFERRED] Firebase pending
- [ ] `ILNotificationPermission` protocol (Domain) + impl: status, request, settings URL; permission prompt after a save with reminder on or a load with any reminder on, once (criterion 31); tests with a mock [DEFERRED] Firebase pending
- [ ] Push hint on the reminder card with "Mở Cài đặt" when denied (criterion 29); `showsPushHint` in `ILMemorialEditStateModel`; ViewModel tests for allowed / denied / not asked [DEFERRED] Firebase pending
- [ ] `ILPushRegistrationRepository` + impl + endpoints: register after sign-in, at app start with a session and on token change (criterion 30) — blocked on ⚠️ contract [DEFERRED] contract pending
- [ ] Sign-out: unregister (best effort, before revoke), FCM `deleteToken`, `removeAllDeliveredNotifications`; on session expiry `deleteToken` + delivered-notification removal (criterion 4) — unregister blocked on ⚠️ contract [DEFERRED] contract pending
- [ ] `ILAccountTimeZoneRepository` + impl + endpoint and `ILAccountTimeZoneReporter` (sign-in, app active, `NSSystemTimeZoneDidChange`) (criterion 34) — blocked on ⚠️ contract [DEFERRED] contract pending
- [ ] Deep link: `ILPushRoute` (`.memorialEntry(id)`), `AppCoordinator` → main tab Home → `ILHomeCoordinator.showMemorial(entryID:)` → `ILMemorialCoordinator.showEntry(id:)`; `MemorialGetEndpoint` + `ILMemorialRepository.load(id:)`; 404 → list + "Mục này không còn trong sổ giỗ."; no session → Login (criterion 33) — payload keys blocked on ⚠️ contract [DEFERRED] contract pending
- [ ] Notification-list hand-off: a memorial item in `Docs/Specs/Notifications/` emits `.memorialEntry(id)` — tracked in that spec; this task only checks the route is used [DEFERRED] Notifications spec
- [ ] Manual QA on device: push arrives with the relationship only (lock screen), opening it opens the entry, denied permission shows the hint and the list still has the reminder, signed-out device receives nothing [NOT RUN] after push

## Phase 9 — Portrait (FR-MEM-011) — later, blocked on the backend photo route

- [x] Photo picker + HEIC/HEIF → JPEG (long edge ≤ 2048, 5 MiB guard), upload/replace/remove and `photo_url` display, `MemorialPhotoEnabled = true`; PHPicker in `ILMemorialEditViewController`, photo block in `ILMemorialEditStateModel`; repository upload/delete (`ILMemorialRepositoryImpl`) — compile-only [2026-11-17]
- [ ] Photo E2E on device — routes now deployed; needs manual upload/replace/delete on a device (no simulator)

## Deferred (separate feature, not blocking Memorial)

- Family tree ("Gia phả") adding an entry to the book — `genealogy` product spec.
- The notification list screen and the account-wide notification switch UI — `Docs/Specs/Notifications/` and a settings feature.

## Phase 10 — P4 integration (2026-11-16)

- [x] I1 `ILMemorialDTO` / `ILMemorialMapper`: v1+v4.0 decode, leap month, explicit relationship table, `GET /v1/memorials/{id}`, photo upload/delete endpoints
- [x] I2 Core Data `InnerLamp 7` (`Memorial` store split; leap flag, owner account; dead attributes removed), account-scoped local data source, backup/file protection, session cleaner + reminder cleanup on sign-out, migration test from model 5
- [x] I3 `MultipartFormData` + `MultipartUploading` on `NetworkServiceImpl` (separate protocol, existing mocks untouched)
- [x] I4 Repository photo upload/delete, `photoTooLarge`/`photoUnsupported`, 413/415 mapping, 5 MiB client guard
- [x] I5 Local reminders: planner (60 entries, one pending each — AC MEM-RMD-08), scheduler, DI one-line cutover, notification router → `.memorialEntry(id)`
- [x] I6 Form: sync-to-Reminders switch removed, lunar leap switch, nearest old reminder choice, delete confirmation, denied-permission hint, photo block behind the flag
- [x] I7 Tests: `ILMemorialProductVectorTests` (3 files, read from `InnerLampTests/Fixtures`), planner, migration, photo repository, D1 wiring; `Scripts/sync-product-vectors.sh`
- [x] I8 Photo UI behind `MemorialPhotoEnabled`; list/highlight portraits only when enabled; cache keyed by entry id
- [ ] Photo E2E — manual on device (routes deployed)
- [ ] Push/server reminders — blocked: backend Phase 8–10 (D1 cutover) [DEFERRED] BE Phase 8–10 pending
- [x] P7: empty state without "Lấy từ gia phả"; Add disabled at 100 entries with notice; 401 keeps the draft and shows session expired
- [ ] Visual QA on a physical device, light/dark, long names, Dynamic Type [NOT RUN] needs physical device

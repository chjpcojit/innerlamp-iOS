# Changelog — Memorial Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this folder. All three
files share one changelog since they change together as one spec unit. Newest version first.

## v3.2 (2026-10-14)

- Step 4 of the docs rewrite: `Docs/Assumptions/Memorial/AS-Memorial-001…006` deleted (product spec v2.1 supersedes them). `AGENTS.md` §10.3 says entries are never deleted; anh Đức decided to delete them for this feature on 2026-10-14. Code `@ai` markers, the scene `README.md` and `TD-Memorial-001` now cite the product IDs instead.
- `requirements.md` criterion 28: nearest-choice rule taken from product FR-MEM-007 @ v2.1; the `⚠️ Not confirmed (product)` marker is resolved.
- `tasks.md`: the "close AS-Memorial" task is done.

## v3.1 (2026-10-14)

- `requirements.md`: criterion 8 also removes the "Xem gia phả" button under a non-empty list (product owner, 2026-10-14: not kept for now); out-of-scope line updated; question moved to resolved.
- `design.md`: `.openFamilyTree` route removed from the coordinator map.
- `tasks.md`: new task to remove the button, the route and its strings.

## v3.0 (2026-10-14)

Moves the spec to the cross-platform product spec innerlamp-be `docs/product/memorial/product.md` @ v2.1
(v2.0 = server-sent reminders, ADR-0001 + ADR-0002 Accepted; v2.1 = the account-wide notification
switch answer) and the contract `docs/specs/api/openapi.yaml` @ bf23f8b (memorial operations unchanged
since 5f4ca56). Docs only; no code changed.

- `requirements.md`: header cites product @ v2.1, the two ADRs and the dependency on `Docs/Specs/Notifications/`; `Implements` drops FR-MEM-009 (Removed) and lists BR-MEM-13 / NFR-MEM-04 as backend-only. "Constraints" rewritten: the server sends reminders, the app schedules nothing. Criteria renumbered 1–43. Removed: local scheduling, permission-before-scheduling and the Reminders-app criteria (old 28–30), the Reminders-app saved message and default (old 12, 20), `reminder.timezone` per entry (old 27). Added: sign-out stops push and clears delivered notifications (4), session expiry also clears the offline copy (3), "Có nhắc" regardless of device permission (7), no "Lấy từ gia phả" on the empty state (8), nearest choice for old reminder values (28), push hint with "Mở Cài đặt" (29), FCM token registration (30), permission prompt (31, platform), push text as sent — relationship only (32), open a reminder → entry (33), account time zone (34), no `reminder.timezone` / `add_to_os_reminder` (35), server failure → offline copy with a line (36), no-copy state (37), §3.1.1 write errors (38), offline copy per account (39). Entry deleted elsewhere on save or delete → "Mục này không còn trong sổ giỗ." (23, 26). All copy now from product §3.1.1. Error → UI table updated. Pending re-derived against product v2.1. Resolved: 5xx fallback, copy, permission denied, other-device stale notification, Reminders-app sub-questions, out-of-range reminder values, account-wide switch (push only, product owner 2026-10-14).
- `design.md`: Overview — server-sent reminders, push as app-wide `Core/Push/` infrastructure. Layers: removed the planned `UNUserNotificationCenter` scheduler and EventKit writer; added push service, notification permission, push registration, account time zone, deep link, app configuration (entitlement, FirebaseMessaging, per-environment config), `MemorialGetEndpoint`, session-expiry cleanup, offline copy keyed by account; `syncToReminders` and the Reminders-app UI marked for removal. Step-by-step Flow: Load drops the re-plan step and gains the permission prompt; Save/Delete schedule/cancel nothing and handle 404 as "no longer in the book"; new flows P (sign-in → token → time zone), O (sign-out), N (open a reminder). "Server sync": stop sending `add_to_os_reminder` before the backend removes it (the contract rejects unknown fields), never send `reminder.timezone`. Vectors: the three client files only (`reminder-moment.json` is backend-only).
- `tasks.md`: Phase 6 updated for product v2.1 (empty-state tree card, offline copy per account and on server failure, 404 handling, nearest reminder choice, §3.1.1 copy). Old Phase 7 (local reminders + EventKit) replaced by new Phase 7 (remove the stubs, `syncToReminders`, the Reminders-app row, `add_to_os_reminder` and their copy) and new Phase 8 (FCM push, permission, hint, registration, sign-out, account time zone, deep link). Portrait moves to Phase 9. Phase 5 gains closing `AS-Memorial-002` and `TD-Memorial-001`. Added `[x]` for the Me-tab sign-out cache cleanup (verified in `ILSessionDataCleanerImpl`).
- Reason: product owner decisions of 2026-10-14 (ADR-0001, ADR-0002, product v2.0/v2.1). Major bump: scope change, new Phases, flow structure changed.
- Correction to v2.0: "sign-out keeps the Core Data cache" was wrong for the Me-tab sign-out — `ILSessionDataCleanerImpl` already deletes `ILMemorialMO`. The real gaps are session expiry (`AppCoordinator.handleSessionExpired` deletes only the user) and the copy not being tied to an account.
- New drift found (code vs product v2.1): the empty state shows the "Lấy từ gia phả" card (FR-MEM-002; product matrix has iOS `done`); a delete 404 reports "Đã xóa…" (FR-MEM-005); `add_to_os_reminder` is sent `true` by default.
- Open: `⚠️ Not confirmed (product)` — nearest-choice tie-break and range edges (criterion 28). `⚠️ Not confirmed (contract)` — push token register/remove (criteria 4, 30), memorial reminder payload / list-item keys (33), account time zone operation (34). Blocker outside the specs: Firebase project, per-environment config and APNs key (owner).

## v2.0 (2026-10-14)

Retroactive rewrite against the cross-platform product spec innerlamp-be
`docs/product/memorial/product.md` @ v1.0 and the contract `docs/specs/api/openapi.yaml` @ 5f4ca56.
Docs only; no code changed.

- `requirements.md`: new header `Product spec` / `Contract` / `Implements` (BR-MEM-01…12, FR-MEM-001…013 with FR-MEM-011 later, NFR-MEM-01…03 — the whole iOS column of product §4.2). Criteria numbered 1–36, each ending with the product ID it implements or `(platform)`. Product decisions removed from this file and cited instead (leap months, delete confirmation, reminder mechanism, storage/offline, year range, portrait). New section "Constraints from the product spec" (§2.7, §3.6 rows for iOS). New "Error → UI mapping" table citing operations, not schemas. Criteria now state what product v1.0 requires; what the code does not meet yet is listed in "Pending" with criterion numbers. Six `⚠️ Not confirmed (product)` markers added (see hand-back below).
- `design.md`: Overview maps the product constraints to iOS layers; Layers table gains a State column (built / change / planned) and planned rows (reminder protocol + `UNUserNotificationCenter` scheduler, EventKit writer, sign-out hook, product vectors). Step-by-step Flow rewritten as Load (L-1…L-5), Save (S-1…S-6), Delete (D-1…D-5), adding the planned session check, delete confirmation and reminder steps. "Server sync" now cites the four operations instead of copying body fields; iOS mapping decisions kept (local UUID, whole-entry PUT, leap recovery, `reminder.timezone`). New "Product vectors" section (script-refreshed pinned copy in the test bundle, never hand-edited) and "Known drift" section.
- `tasks.md`: Phase 1–5 re-verified against the code (task text corrected to real names: `isValid(name:)`, `loadItems`, formatter); added `[x]` only for verified behavior (offline write refusal, 409 message, network logging without PII). New Phase 6 (product v1.0 drift, all `[ ]`), Phase 7 (reminders, all `[ ]`), Phase 8 (portrait, later). Phase 5 gains README refresh and closing the superseded assumptions.
- Reason: move to the three-layer documentation model (product spec → contract → platform spec). Major bump: structure change and new Phases.
- Drift found (code vs product v1.0): no leap-month choice, leap flag always `false` and dropped on load (BR-MEM-04); year menu = current year + 96 before (BR-MEM-03); lunar day 30 of a 29-day month with a known year silently saved as day 29 (BR-MEM-03, fails `death-date-conversion.json`); delete without confirmation (BR-MEM-12); reminders and Reminders app are stubs (FR-MEM-008/009, `TD-Memorial-001`); guest preview opens an empty book instead of a sign-in prompt (FR-MEM-001); the offline cache survives sign-out and is not per account (BR-MEM-01, NFR-MEM-02); offline with no cache and any load failure show the empty state (FR-MEM-010); no client length checks, the 400 shows one generic message (FR-MEM-012/013); 404 on save leaves the user on the form (FR-MEM-004); `reminder.timezone` not sent (BR-MEM-11, Appendix B item 3); ordinal `0` collapsed to `nil` (vector `next-anniversary.json` "died today"); vectors not run (NFR-MEM-03).
- Superseded assumptions (cited by product ID now; files kept, closing is a Phase 5 task): `AS-Memorial-001` (local only → BR-MEM-01, already Invalidated), `AS-Memorial-002` (reminder mechanism → FR-MEM-008, FR-MEM-009, BR-MEM-11), `AS-Memorial-003` (leap month skipped → contradicted by BR-MEM-04/05), `AS-Memorial-004` (delete without confirmation → contradicted by BR-MEM-12), `AS-Memorial-005` (death-date mapping → BR-MEM-03/04/10 + contract; its day-30 and dropped-leap parts contradict the product), `AS-Memorial-006` (server source, offline read-only → BR-MEM-01, FR-MEM-010).
- Hand back to `ba-writer` (product spec, not edited here):
  1. FR-MEM-008 / FR-MEM-009: what the user sees when notification or Reminders access is denied.
  2. FR-MEM-009: Reminders item on edit / reminder off / delete; one item per anniversary or yearly; the account-level flag adds duplicates from a second iPhone on the same iCloud.
  3. FR-MEM-005 vs FR-MEM-008: another device's notification only stops when it next loads the book — acceptable?
  4. BR-MEM-11: entries whose server reminder is outside the fixed choices (contract allows 0–30 days, any `HH:mm`) — what the form shows and saves.
  5. FR-MEM-010 / §3.7: server reachable but failing — offline copy or an error?
  6. Copy not in product or prototype: leap choice and leap marker, "name/note too long", "date not valid", "cannot load offline", delete confirmation.
  7. Matrix §4.2 iOS column: FR-MEM-001 `done` → `drift` (guest); FR-MEM-010 `done` → `drift` (no-cache offline, cache not per account); FR-MEM-004, FR-MEM-012, FR-MEM-013 `done` → `in-progress`; BR-MEM-03 drift also covers the lenient day-30 conversion.
- Follow-ups outside this spec: `Scenes/Memorial/README.md` is stale (Phase 5); `Docs/Tech-Debt/Memorial/TD-Memorial-001` should cite FR-MEM-008/009 when next touched; OKF concept still waits for Phase 6–7.

## v1.3 (2026-10-07)

API integration — the backend shipped `/v1/memorials`.

- `design.md`: "Server sync" now documents the four endpoints, the body rules, the lunar/solar mapping and the offline cache policy; remote files added to the layer table.
- `tasks.md`: Phase 4 ticked except the on-device test, per-field validation messages and portrait.
- `requirements.md`: the API ⚠️ item is resolved (see below).
- Decisions (user, 2026-10-07): server is the source of truth with a Core Data offline cache; old local-only entries are discarded. Recorded as `AS-Memorial-005` / `AS-Memorial-006`; `AS-Memorial-001` is now Invalidated.
- Reason: replace the local-only storage with the real API.

## v1.2 (2026-10-05)

Implementation-only change — the list screen's add action follows the prototype (`isGio`): no
nav-bar "Thêm" action, and the primary "Thêm người thân" button is sticky at the bottom in every
state. Requirements, design and tasks are unchanged. Kept deliberately (user decision): the
"Xem gia phả" ghost button and the window-level toast instead of the prototype's in-screen banner.
Form-screen differences (card2 background, portrait caption, section-label style, inline save/delete
buttons) were not applied — no decision yet.

## v1.1 (2026-10-03)

Implementation entry — the feature was built from this spec with `il-screen-builder`.

- `requirements.md`: the pending ⚠️ items for leap months, delete safety, portrait and storage were moved to "Open questions (resolved)" as user-accepted defaults, and the reschedule policy became an assumption inside the reminder item; each is recorded in `Docs/Assumptions/Memorial/` (AS-001…004) or `Docs/Tech-Debt/Memorial/` (TD-001, TD-002). The API contract and the reminder mechanism (local notification vs EventKit) stay ⚠️ open.
- `design.md`: aligned with the code — `.editEntry` carries the entity (no async load), `loadItems` replaces `loadEntries`, preview formatting lives in `ILMemorialFormatter`, `Repository.load(id:)` dropped as unused, new generic design-system pieces listed, reminders/portrait marked as stubs.
- `tasks.md`: Phase 1–3 and the documentation items ticked; reminder scheduling, portrait, visual QA, Phase 4 (API) and the OKF concept stay open.
- Tests are written and the test target builds (with the pre-existing, unrelated `InnerLampTests/GRPC` files set aside — they fail on a missing `GRPCProtobuf` module), but XCTest was not run.
- Reason: build and sync the spec with what exists.

## v1.0 (initial)

Initial spec written before implementation, as the work order for building Memorial ("Sổ giỗ
chạp"), derived from the design prototype (`InnerLamp Prototype.dc.html`, screens `isGio` and
`isGioEdit`).

- Scope confirmed with the user (2026-10-03): list + add/edit/delete screens; data stored
  locally in Core Data now, server API later (no API exists yet); entry is a "Sổ giỗ" link
  beside "Lịch âm" in Home's week strip, opened by `ILHomeCoordinator`; spec first, then build
  with `il-screen-builder`.
- Open (⚠️ Not confirmed, all in `requirements.md` Pending): backend API contract, reminder
  mechanism (UNUserNotificationCenter / Apple Reminders via EventKit), reschedule policy,
  portrait source/storage, leap-month behaviour, delete confirmation.
- Gaps found in the codebase while writing it: no lunar→solar conversion in `ILLunarCalendar`,
  no notification/EventKit code, and no Core Data entity for this feature — all listed in
  `design.md` and `tasks.md`.

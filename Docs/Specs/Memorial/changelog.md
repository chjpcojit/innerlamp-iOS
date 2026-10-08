# Changelog — Memorial Spec

Tracks version history for `requirements.md`, `design.md`, and `tasks.md` in this folder. All three
files share one changelog since they change together as one spec unit. Newest version first.

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

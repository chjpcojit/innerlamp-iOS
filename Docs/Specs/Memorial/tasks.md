# Tasks — Memorial

Version: 1.3
Last updated: 2026-10-07
Status: implemented (build-verified, tests not run) — local Core Data; reminders and portrait stubbed; no API

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILMemorialViewController` extending `BaseViewController` (list: nav bar with
      "Thêm", banner, highlight card, "THEO NGÀY GIỖ SẮP TỚI" rows, empty state, "Thêm người
      thân" ghost button)
- [x] Create `ILMemorialEditViewController` (portrait, name field + error, relationship chips,
      calendar toggle, day/month/year pickers, preview card, note, reminder card, Save/Delete)
- [x] Create the feature views under `Scenes/Memorial/Views/` (highlight card, entry row, empty
      state, banner, portrait view, reminder card) — reuse `ILChip`/`ILChipFlowView`,
      `ILToggleCardRow`, `ILNavBar`, `ILButton` before building new ones
- [ ] Visual QA against the prototype (`InnerLamp Prototype.dc.html`, screens `isGio` /
      `isGioEdit`), light + dark

## Phase 2 — Logic (Domain + local persistence)

- [x] Add `ILLunarCalendar.lunarToSolar(day:month:year:isLeap:)` + `ILLunarToSolarTests`
- [x] Create `ILMemorialEntity` (+ `ILMemorialRelationship`, `ILMemorialCalendarKind`,
      `ILMemorialReminder`, `ILMemorialNextAnniversary`)
- [x] Create `ILMemorialRepository` protocol
- [x] Create `ILMemorialUseCase` / `ILMemorialUseCaseImpl`: `loadEntries`, `nextAnniversary`
      (lunar incl. 29-day-month rule, solar incl. month-end clamp), `ordinal`, `validate(name:)`,
      `previewLines`, `save`, `delete`
- [x] New Core Data model version with `ILMemorialMO`; `ILMemorialLocalDataSource`;
      `ILMemorialRepositoryImpl` (local only)
- [x] Create `ILMemorialStateModel` and `ILMemorialEditStateModel` (no UIKit import)
- [x] Create `ILMemorialViewModel` + `ILMemorialEditViewModel` (`Input -> Output`, nav events)
- [x] Create `ILMemorialCoordinator` + delegate protocol (pop + banner message hand-off)
- [x] Wire `DIContainer.makeMemorial…` and `ILHomeCoordinator.showMemorial()` (Home v1.7)
- [ ] Reminder scheduling behind a protocol — stubbed (`TD-Memorial-001`), blocked on the ⚠️ reminder-mechanism question
- [ ] Portrait picker + file storage — placeholder avatar for now (`TD-Memorial-002`), blocked on the ⚠️ portrait question
- [x] Unit tests (written and build-verified; not run — XCTest needs a simulator/device): `ILMemorialViewModelTests`, `ILMemorialEditViewModelTests`,
      `ILMemorialUseCaseTests` (mock the repository/use case directly)

## Phase 3 — Localization

- [x] Add `memorial.*` keys to `vi.json` (all copy in requirements; no hardcoded text)

## Phase 4 — API integration

- [x] Contract confirmed with the backend (`/v1/memorials`, REST; see design.md "Server sync")
- [x] Create `ILMemorialDTO` + `ILMemorialMapper`
- [x] Create the `Endpoint` conformances (list / create / update / delete)
- [x] Server-first `ILMemorialRepositoryImpl` with the Core Data offline cache; `replaceAll` on the local data source
- [x] Unit tests for the mapper and the repository (success, offline, 401, 409, 400, 404) — written, test target builds, not run
- [x] Form limits solar days per month (Feb 29 max) so the server never sees 31 April
- [ ] Manual test against the backend running on the Mac (`make run`, `:8080`) on a physical device
- [ ] Per-field validation messages for 400 `VALIDATION_ERROR` (one generic message today)
- [ ] Portrait upload — blocked on the backend photo route

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Memorial/README.md`
- [x] Record assumptions in `Docs/Assumptions/Memorial/` (bilingual) for every ⚠️ item that
      code is built on top of (leap months, no delete confirmation, reschedule policy)
- [ ] `Docs/Knowledge/features/memorial.md` (OKF concept) — hold off until local persistence is
      verified end to end (and API sync, if added). See `Docs/Specs/OKF.md`.

## Deferred (separate feature, not blocking Memorial)

- Family tree ("Gia phả") adding an entry to the book — separate feature.

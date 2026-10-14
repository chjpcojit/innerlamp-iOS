# Tasks — MeritBook

Version: 1.0
Last updated: 2026-10-11
Status: in-progress (Phase 1–2 done; Phase 3 blocked on API contract)

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI

- [x] `ILMeritBookViewController` with sticky header (`ILStickyHeaderBand` + `ILNavBar`)
- [x] Views: stats, history, letter, monthly (+ dashed note), build cards
- [x] New icon `row_calendar` + `ILIcons.rowCalendar`
- [ ] Visual QA against prototype screen `merit` on a physical device (light + dark)

## Phase 2 — Logic

- [x] Entities, repository protocol, use case
- [x] `ILMeritBookRepositoryImpl` (sample data)
- [x] `ILMeritBookViewModel` + `ILMeritBookStateModel`
- [x] `ILMeritBookCoordinator`; DI wiring; Profile `.openOffering` → `.openMeritBook`
- [x] Localization keys `meritBook.*`
- [x] Unit tests: `ILMeritBookViewModelTests`, `ILMeritBookUseCaseTests` (written, **not yet run** — build-for-testing blocked by GRPCProtobufGenerator)

## Phase 3 — API integration (blocked)

> ⚠️ Not confirmed: merit book API contract.

- [ ] Define contract; add DTO + Mapper + Endpoint
- [ ] Replace sample repository implementation
- [ ] Wire "Cúng dường" to the donation flow (`Offering`)
- [ ] Decide stop-monthly confirmation

## Phase 4 — Docs

- [ ] OKF concept (after verification on device) — `il-okf-writer`

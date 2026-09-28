# Tasks — Events

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3–4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature was built UI-first with mock data. Checked items reflect
> what shipped; unchecked items are real pending work.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILEventsViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: `ILNavBar` + sticky header, `ILChip`
      tabs (3), `ILSectionHeaderView`, hero card, list — per design handoff
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILEventsHeroCardView`,
      `ILEventsListItemView`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `events`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILEventsEntity` + `ILEventsFeaturedEntity` + `ILEventsEventEntity`
      + `ILEventsTone` + `ILEventsStatus`
- [x] Create `ILEventsStateModel` + `ILEventsTab` + display-ready models
- [x] Create `ILEventsUseCase` / `ILEventsUseCaseImpl` (`getEvents()` — mock)
- [x] Create `ILEventsViewModel` (`Input -> Output`, `ILEventsNavEvent`,
      Entity→StateModel mapping, status/section label formatting)
- [x] Create `ILEventsCoordinator` (leaf — `.goBack` pop+finish; `.openRegister`
      TODO)
- [x] Wire `DIContainer.makeEventsUseCase/ViewModel/Coordinator`
- [x] Wire `ILSanghaCoordinator.openEvents` + `ILHomeCoordinator.showEvents()`
- [x] Unit tests: `InnerLampTests/ILEventsViewModelTests.swift` (7 tests) —
      initial state, viewDidLoad, tab switching, status mapping, nav events

## Phase 3 — API integration (pending; blocked on contract)

> ⚠️ Not confirmed: the events/courses/registrations API contract(s) (see
> `requirements.md` Pending). Everything below is blocked until a contract
> exists.

- [ ] Define the events API contract(s) with the backend team
- [ ] Create `ILEventsDTO` + `ILEventsMapper` (once the contract is confirmed)
- [ ] Create `EventsEndpoint` under `Data/DataSources/Remote/`
- [ ] Create `ILEventsRepository` protocol + `ILEventsRepositoryImpl` wrapping
      `NetworkService`
- [ ] Replace the mock data in `ILEventsUseCaseImpl.getEvents()` with real
      repository calls
- [ ] Add loading / error / offline states
- [ ] Update `ILEventsViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Register destination (pending, separate scope)

- [ ] Build the Register screen (`register`) and wire `.openRegister(eventId:)`
      to navigate to it
- [ ] Update `InnerLamp/Presentation/Scenes/Events/README.md` changelog

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Events/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/events.md` (OKF concept) — hold off until the
      events API (Phase 3) lands. See `Docs/Specs/OKF.md`.

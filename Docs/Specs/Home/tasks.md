# Tasks — Home

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3 pending — mock data, no API)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature was built UI-first with mock content, matching the
> project's preferred workflow. Checked items reflect what shipped; unchecked
> items are real pending work.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILHomeViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: greeting header, week strip, lunar
      hero card, photo grid, temple carousel, statistics, bead card, bell card,
      suggested-session list, articles list — per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILHomeGreetingHeaderView`,
      `ILHomeWeekCalendarView`, `ILHomeLunarHeroCardView`,
      `ILHomeEventsCarouselView`, `ILHomePhotoGridView`,
      `ILHomeTempleCarouselView`, `ILHomeBellCardView`, `ILHomeArticleListView`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (block `isHome`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILHomeEntity` + all sub-entities/enums (`ILHomeSessionKind`,
      `ILHomeSessionTone`, `ILHomeSessionGlyph`, `ILHomeEventTone`, …)
- [x] Create `ILHomeStateModel` + presentation models (greeting, week day,
      lunar hero, event, photo, temple, article, suggested session)
- [x] Create `ILHomeUseCase` / `ILHomeUseCaseImpl`:
      - `getInitialState()` — mock content + `KeychainService` name read + real
        `ILLunarCalendar` conversion
      - `incrementBead(_:)` (wrap to 1 after goal) / `resetBeads(_:)`
- [x] Create `ILHomeViewModel` (`Input -> Output`, `ILHomeNavEvent`, 8 cases,
      `navigationEventPublisher`, Entity→StateModel mapping)
- [x] Create `ILHomeCoordinator` (spawns child coordinators for 8 destinations)
- [x] Wire `DIContainer.makeHomeUseCase/ViewModel/Coordinator`
- [x] Wire `ILMainTabCoordinator` to use `ILHomeCoordinator` as the Home tab
- [x] Unit tests: `InnerLampTests/ILHomeViewModelTests.swift` (13 tests, driven
      via `Input` publishers) — covering initial state (incl. photos/temples/
      articles/bell), guest-name fallback, bead increment/reset, and the nav
      events (Mala, LunarCalendar, Photos, Bell, Events, Article, Temple,
      MeditationSetup)

## Phase 3 — API integration (pending; blocked on contract)

> ⚠️ Not confirmed: the dashboard/content API contract(s) — no home-dashboard
> endpoint in `Docs/Specs/API/openapi.yaml` v3.9. Everything below is blocked
> until a contract exists.

- [ ] Define the dashboard/content API contract(s) with the backend team
- [ ] Create `ILHomeDTO` + `ILHomeMapper` (once the contract is confirmed)
- [ ] Create `HomeDashboardEndpoint` (or per-section endpoints) under
      `Data/DataSources/Remote/`
- [ ] Create `ILHomeRepository` protocol + `ILHomeRepositoryImpl` wrapping
      `NetworkService`
- [ ] Replace the mock content in `ILHomeUseCaseImpl.getInitialState()` with
      real repository calls (daily quote, statistics, sessions, photos, temples,
      articles, events)
- [ ] Replace the `KeychainService` name read with a real session/current-user
      service
- [ ] Update `ILHomeViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Home/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/home.md` (OKF concept) — hold off until the
      dashboard API (Phase 3) lands. See `Docs/Specs/OKF.md`.

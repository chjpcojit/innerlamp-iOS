# Tasks — Home

Version: 1.11
Last updated: 2026-10-11
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
- [x] Temples + Buddhas/Bodhisattvas carousels read `GET /v1/temples/top` /
      `GET /v1/deities/top` via `ILTempleRepository` / `ILDeityCatalogRepository`
      (see changelog v1.1)
- [x] Buddhas/Bodhisattvas carousel: drop the bundled-catalog fallback, show
      "Đang cập nhật" when empty (see changelog v1.2)
- [x] Articles section reads `GET /v1/articles/top` via `ILArticleRepository`
      (`ILHomeUseCase.loadTopArticles()`; contract confirmed 2026-09-30, see
      `Docs/Specs/Article/design.md`) + unit tests
- [x] Temples + articles sections: show "Đang cập nhật" when the server answers
      empty or fails (same as deities; see changelog v1.5) + unit tests
- [x] Temples / deities / articles show skeleton cards while loading (see changelog v1.6)
- [x] "Sổ giỗ" link beside "Lịch âm" in `ILHomeWeekCalendarView` →
      `ILHomeNavEvent.openMemorial` → `ILHomeCoordinator.showMemorial()` (added with the
      Memorial feature, see `Docs/Specs/Memorial/tasks.md`; the Memorial screens must exist first)
- [ ] Replace the remaining mock content in `ILHomeUseCaseImpl.getInitialState()`
      with real repository calls (statistics, sessions)
- [x] Load the "Ảnh chùa đẹp" block from `GET /v1/gallery/top`
      (`ILHomeUseCase.loadTopPhotos()`, `ILHomePhotoGridView` uses
      `ILRemoteImageView`); unit tests written, not run
- [ ] Replace the `KeychainService` name read with a real session/current-user
      service
- [x] Unit tests for the temple/deity carousels (`ILHomeUseCaseTests` with mock
      repositories, `ILHomeViewModelTests` async load + card formatting)
- [x] Events carousel reads `GET /v1/calendar/events` (v1.11): `CalendarEventsEndpoint`,
      `ILCalendarEventsDTO`, `ILCalendarEventMapper`, `ILCalendarEventRepository(+Impl)`,
      `ILHomeUseCaseImpl` takes `calendarEventRepository`; tests in `ILHomeUseCaseTests`
      and `ILCalendarEventsTests`
- [ ] Offline cache for the events carousel (TD-Home-003)
- [ ] Manual device test of the events carousel against the dev backend (current month
      first, Rằm/Mùng 1 density — AS-Home-003)
- [ ] Loading / error UI for the server-backed carousels
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Home/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/home.md` (OKF concept) — hold off until the
      dashboard API (Phase 3) lands. See `Docs/Specs/OKF.md`.

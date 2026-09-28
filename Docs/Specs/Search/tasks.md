# Tasks — Search

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILSearchViewController` extending `BaseViewController`
- [ ] `setupViews()`: search field + "Hủy", result tab chips, featured result
      card, in-library list, empty IL-State with request button + suggestions
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire keyword submit / tab taps / result taps /
      request tap to `Input`, render `Output.state`
- [ ] Visual QA against the design prototype (screens `search`, `empty`)

## Phase 2 — Logic (Domain + real behavior)

- [ ] Create `ILSearchEntity` (pure business fields only)
- [ ] Create `ILSearchStateModel` (UI state, no UIKit import)
- [ ] Create `ILSearchUseCase` / `ILSearchUseCaseImpl`:
      - `search(keyword:)` — stub only (no confirmed backend contract)
      - `requestContent(keyword:)` — stub only
      - `ILSearchError` (feature error type)
- [ ] Create `ILSearchViewModel` (`Input -> Output`, `ILSearchNavEvent`)
- [ ] Create `ILSearchCoordinator` + delegate protocol
- [ ] Wire `DIContainer.makeSearch{UseCase,ViewModel,Coordinator}`
- [ ] Wire the presenting coordinators (`showSearch()` + delegate conformance)
- [ ] Unit tests: `ILSearchViewModelTests.swift` (mock UseCase)

## Phase 3 — API integration (pending, blocks feature completion)

> Contracts unconfirmed (see `requirements.md` Pending ⚠️).

- [ ] Define the catalog-search API contract (endpoint, request params,
      result shape, pagination, error cases)
- [ ] Define the content-request API contract (or confirm it is out of scope)
- [ ] Create `ILSearchDTO` + `ILSearchMapper` (only after contracts confirmed)
- [ ] Create the `Endpoint` conformances under `Data/DataSources/Remote/`
- [ ] Create `ILSearchRepository` protocol + `ILSearchRepositoryImpl`
- [ ] Inject the repository into `ILSearchUseCaseImpl.init`; replace stubs
- [ ] Map network/HTTP errors to `ILSearchError` cases
- [ ] Update `ILSearchViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Search/README.md`
- [ ] `Docs/Knowledge/features/search.md` (OKF concept) — after Phase 3 lands

## Deferred (separate feature, not blocking Search)

- Reader, Talk, MeditationSetup screens that results navigate to.

# Tasks — Library

Version: 1.1
Last updated: 2026-09-20
Status: in-progress — Phase 1–2 implemented on mock catalog (visual QA pending); API integration pending

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [x] Add `ILSearchBarView` to `DesignSystem/Components/`
- [x] Add `ILFeatureCardView` to `DesignSystem/Components/`
- [x] Add `ILLibraryCategoryChipsView` (`Scenes/Library/Views/`)
- [x] Add `ILLibraryListView` (`Scenes/Library/Views/`)
- [x] Create `ILLibraryViewController`: pinned title, scroll content, pinned `ILBottomNavBar(.lib)`
- [x] Add `library.*` keys to `vi.json`; add any missing `ILTypography` / `ILColors` tokens
- [ ] Visual QA against prototype screen `lib` (light + dark)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILLibraryEntity` (+ item / featured / kind / tone / category types)
- [x] Create `ILLibraryStateModel`
- [x] Create `ILLibraryUseCase` / `ILLibraryUseCaseImpl`: `getCatalog()` (mock — stub until
      Phase 3), `items(in:category:)` (real in-memory filter)
- [x] Create `ILLibraryViewModel` (`Input -> Output`, `ILLibraryNavEvent`, duration formatting,
      section title, chip selection)
- [x] Create `ILLibraryCoordinator` + `ILLibraryCoordinatorDelegate`
- [x] Wire `DIContainer.makeLibraryUseCase/ViewModel/Coordinator`
- [x] Wire `AppCoordinator.showLibrary()` + `ILLibraryCoordinatorDelegate` conformance
- [x] Home entry: `libraryTabTapped` Input, `ILHomeNavEvent.openLibrary`,
      `ILHomeCoordinatorDelegate.homeDidRequestLibrary`, `AppCoordinator` conformance
- [x] Unit tests: `InnerLampTests/ILLibraryViewModelTests.swift`; update
      `ILHomeViewModelTests` for the new Input and add the Home → Library event test

## Phase 3 — API integration (pending, blocks feature completion)

- [ ] Confirm the catalog contract with backend (endpoint, response shape, categories, featured,
      pagination, error cases) — see ⚠️ in `requirements.md`
- [ ] Create `ILLibraryDTO` + `ILLibraryMapper` (only after the contract is confirmed)
- [ ] Create the `Endpoint` conformance (`Data/DataSources/Remote/`)
- [ ] Create `ILLibraryRepository` protocol + `ILLibraryRepositoryImpl` wrapping `NetworkService`
- [ ] Inject the repository into `ILLibraryUseCaseImpl.init`; replace the mock `getCatalog()`
      (becomes `async throws`)
- [ ] Map network errors to `ILLibraryError` cases; ViewModel drives `.loading` / `.failure`
- [ ] Update `ILLibraryViewModelTests` with a mock repository for success/failure paths

## Phase 4 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Library/README.md` (status table, nav events, gaps) + add to
      `membershipExceptions` in `project.pbxproj`
- [ ] `Docs/Knowledge/features/library.md` (OKF concept) — hold off until Phase 3 lands so it
      describes real end-to-end behavior. See `Docs/Specs/OKF.md`.

## Deferred (separate feature, not blocking Library)

- Search / Empty results screens — Library's search bar emits `.openSearch`.
- Sutra Detail, Reader, Dharma talk, Player screens — row/featured taps emit `.openItem`.
- Lamp / Sangha / Me tab destinations.
- Loading / error / offline system states for first load (needs Phase 3 async load).

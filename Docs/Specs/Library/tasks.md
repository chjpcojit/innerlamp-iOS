# Tasks — Library

Version: 2.0
Last updated: 2026-09-27
Status: in-progress — Phase 1–2 implemented on mock catalog (visual QA pending);
API integration pending; Library is now a Main tab

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [x] Add `ILSearchBarView` to `DesignSystem/Components/`
- [x] Add `ILFeatureCardView` to `DesignSystem/Components/`
- [x] Add `ILLibraryCategoryChipsView` (`Scenes/Library/Views/`)
- [x] Add `ILLibraryListView` (`Scenes/Library/Views/`)
- [x] Create `ILLibraryViewController`: pinned title, scroll content (no
      embedded `ILBottomNavBar` — the tab bar is owned by `ILMainTabBarController`)
- [x] Add `library.*` keys to `vi.json` (including the 4 section-title keys);
      add any missing `ILTypography` / `ILColors` tokens
- [ ] Visual QA against prototype screen `lib` (light + dark)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILLibraryEntity` (+ item / featured / kind / tone / category types)
- [x] Create `ILLibraryStateModel`
- [x] Create `ILLibraryUseCase` / `ILLibraryUseCaseImpl`: `getCatalog()` (mock —
      stub until Phase 3), `items(in:category:)` (real in-memory filter)
- [x] Create `ILLibraryViewModel` (`Input -> Output`, `ILLibraryNavEvent`,
      duration formatting, section title, chip selection)
- [x] Create `ILLibraryCoordinator` (no delegate — Library is a Main tab)
- [x] Wire `DIContainer.makeLibraryUseCase/ViewModel/Coordinator`
- [x] Wire `ILMainTabCoordinator` to use `ILLibraryCoordinator` as the Library
      tab (this replaced the v1.x `AppCoordinator.showLibrary()` + delegate +
      Home "library tab" wiring, which were removed)
- [x] Wire `.openItem(id:.sutra)` → `showSutraDetail(id)` (lib → detail →
      reader flow per design handoff)
- [x] Unit tests: `InnerLampTests/ILLibraryViewModelTests.swift` (13 tests) —
      per-Input ViewModel tests + UseCase filter tests

## Phase 3 — API integration (pending, blocks feature completion)

- [ ] Confirm the catalog contract with backend (endpoint, response shape,
      categories, featured, pagination, error cases) — see ⚠️ in `requirements.md`
- [ ] Create `ILLibraryDTO` + `ILLibraryMapper` (only after the contract is confirmed)
- [ ] Create the `Endpoint` conformance (`Data/DataSources/Remote/`)
- [ ] Create `ILLibraryRepository` protocol + `ILLibraryRepositoryImpl` wrapping
      `NetworkService`
- [ ] Inject the repository into `ILLibraryUseCaseImpl.init`; replace the mock
      `getCatalog()` (becomes `async throws`)
- [ ] Map network errors to `ILLibraryError` cases; ViewModel drives `.loading`
      / `.failure`
- [ ] Update `ILLibraryViewModelTests` with a mock repository for success/failure
      paths

## Phase 4 — Remaining destinations (pending, separate scope)

- [ ] Build the Search screen and wire `.openSearch`
- [ ] Resolve and build the `.meditation` destination (Setup/Session?) — see ⚠️
      in `requirements.md`
- [ ] Resolve and build the `.talk` destination (Talk screen) for rows + the
      featured card
- [ ] Update `InnerLamp/Presentation/Scenes/Library/README.md` changelog

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Library/README.md` (status table, nav
      events, gaps) + add to `membershipExceptions` in `project.pbxproj`
- [ ] `Docs/Knowledge/features/library.md` (OKF concept) — hold off until Phase 3
      lands so it describes real end-to-end behavior. See `Docs/Specs/OKF.md`.

## Deferred (separate feature, not blocking Library)

- Search / Empty results screens — Library's search bar emits `.openSearch`.
- Dharma talk, Meditation detail, Player screens — `.openItem` / featured taps
  for those kinds.
- Loading / error / offline system states for first load (needs Phase 3 async load).

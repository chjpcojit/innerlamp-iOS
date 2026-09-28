# Tasks — Downloads

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILDownloadsViewController` extending `BaseViewController`
- [ ] `setupViews()`: header (count + size), storage bar with colored segments,
      item list with per-item state indicators
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire item taps / back to `Input`, render `Output.state`
- [ ] Visual QA against the design prototype (screen `downloads`)

## Phase 2 — Logic (Domain + real behavior)

- [ ] Create `ILDownloadsEntity` (pure business fields only)
- [ ] Create `ILDownloadsStateModel` (UI state, no UIKit import)
- [ ] Create `ILDownloadsUseCase` / `ILDownloadsUseCaseImpl`:
      - `loadDownloads()` — stub only (catalog source unconfirmed)
      - `storageUsage()` — local computation
- [ ] Create `ILDownloadsViewModel` (`Input -> Output`, `ILDownloadsNavEvent`)
- [ ] Create `ILDownloadsCoordinator` + delegate protocol
- [ ] Wire `DIContainer.makeDownloads{UseCase,ViewModel,Coordinator}`
- [ ] Wire `SettingsCoordinator.showDownloads()` (and Reader/SutraDetail) +
      delegate conformance
- [ ] Unit tests: `ILDownloadsViewModelTests.swift` (mock UseCase)

## Phase 3 — API integration (pending, blocks feature completion)

> Catalog source unconfirmed (see `requirements.md` Pending ⚠️).

- [ ] Confirm the downloadable-catalog source (backend API vs bundled metadata
      vs local download records)
- [ ] Define the list/catalog contract (endpoint + response shape + error cases)
- [ ] Create `ILDownloadsDTO` + `ILDownloadsMapper` (only after confirmation)
- [ ] Create the `Endpoint` conformance (if API) under `Data/DataSources/Remote/`
- [ ] Create `ILDownloadsRepository` protocol + `ILDownloadsRepositoryImpl`
- [ ] Inject the repository into `ILDownloadsUseCaseImpl.init`; replace the stub
- [ ] Map network/HTTP errors to feature error cases
- [ ] Update `ILDownloadsViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Downloads/README.md`
- [ ] `Docs/Knowledge/features/downloads.md` (OKF concept) — after Phase 3 lands

## Deferred (separate feature, not blocking Downloads)

- The shared download engine / background transfer — a Core concern.
- Reader, Player screens that items open.

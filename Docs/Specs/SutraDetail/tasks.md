# Tasks — SutraDetail

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature has no network layer today; Phase 3 tracks replacing the
> static catalog with a real sutra API.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILSutraDetailViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: dark hero (eyebrow, title, meta, 2
      chips, back + download), progress card, description, TOC, bottom CTA bar —
      per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILSutraDetailHeroView`,
      `ILSutraDetailChapterListView`
- [x] Add `ILTypography.contentHeroTitle` / `scriptureDescription` +
      `ILColors.goldOnDark`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (block `isDetail`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILSutraDetailEntity` + `ILSutraDetailSutraEntity` +
      `ILSutraDetailChapterEntity` + `ILSutraDetailTag`
- [x] Create `ILSutraDetailStateModel` + chapter/tag models
- [x] Create `ILSutraDetailUseCase` / `ILSutraDetailUseCaseImpl` (catalog,
      currentSutra — pure logic)
- [x] Create `ILSutraDetailViewModel` (`Input -> Output`, `ILSutraDetailNavEvent`,
      `sutraID` parameter, duration formatting)
- [x] Create `ILSutraDetailCoordinator` (back pop+finish; `.openReader` → Reader;
      `.openPlayer` → Player; `.download` TODO)
- [x] Wire `DIContainer.makeSutraDetailUseCase/ViewModel/Coordinator`
- [x] Wire `ILLibraryCoordinator` (`openItem` with `kind == .sutra` → SutraDetail)
- [x] Unit tests: `InnerLampTests/ILSutraDetailViewModelTests.swift` (8 tests) —
      load sutra, tag order, current chapter, 5 nav events

## Phase 3 — API integration (pending; blocked on contract)

> ⚠️ Not confirmed: the sutra catalog / chapter API contract(s) (see
> `requirements.md` Pending). Everything below is blocked until a contract
> exists.

- [ ] Define the sutra catalog / chapter API contract(s) with the backend team
- [ ] Create `ILSutraDetailDTO` + `ILSutraDetailMapper` (once the contract is
      confirmed)
- [ ] Create `SutraDetailEndpoint` under `Data/DataSources/Remote/`
- [ ] Create `ILSutraDetailRepository` protocol + `ILSutraDetailRepositoryImpl`
      wrapping `NetworkService`
- [ ] Replace the static catalog in `ILSutraDetailUseCaseImpl` with real data
- [ ] Connect `readingProgress` to real per-user progress
- [ ] Update `ILSutraDetailViewModelTests` + add a mock repository
- [ ] Visual QA on simulator/device (scroll, hero under status bar, dark mode)
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Download destination (pending, separate scope)

- [ ] Build the Download screen (`downloads`) and wire `.download` to it
- [ ] Update `InnerLamp/Presentation/Scenes/SutraDetail/README.md` (note: its
      `.openPlayer` "TODO" row is stale — `.openPlayer` is wired)

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/SutraDetail/README.md` (implementation
      notes, status table, changelog)
- [ ] `Docs/Knowledge/features/sutra-detail.md` (OKF concept) — hold off until
      the sutra API (Phase 3) lands. See `Docs/Specs/OKF.md`.

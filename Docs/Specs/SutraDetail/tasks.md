# Tasks — SutraDetail

Version: 1.3
Last updated: 2026-10-11
Status: in-progress (Phase 1–3 and 6 implemented, build verified; unit tests not run; Phase 4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: since v1.2 the screen reads `GET /v1/sutras/{id}` (Phase 3).

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
- [x] v1.1 design refresh: pinned `ILNavBar` header with scroll hairline, theme-aware
      hero (original name, wrapping chips), translator line, conditional progress
      card / play button, 11-sutra catalog
- [ ] Device check of the v1.1 refresh (light + dark) — user runs on device

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

## Phase 3 — API integration

- [x] Contract confirmed by the backend team (2026-10-07; BE `docs/specs/api/openapi.yaml`)
- [x] `ILSutraDTO` + `ILSutraMapper`, `SutraDetailEndpoint`, `ILSutraRepository` + `ILSutraRepositoryImpl`
- [x] Replace the static catalog: `ILSutraDetailUseCaseImpl.loadSutra(id:)`; entity / ViewModel / StateModel reshaped
- [x] Update `ILSutraDetailViewModelTests` + `ILSutraDetailUseCaseTests`, `ILSutraRepositoryTests`, mock repository — written, not run
- [ ] Run the unit tests (needs a device / simulator destination)
- [ ] Reading progress (TD-SutraDetail-002) · Reader / Player integration (TD-SutraDetail-003)
- [ ] Visual QA on device (hero, empty TOC, long license text, dark mode)

## Phase 6 — Show all API fields (v1.4)

- [x] Backend JSON sample for `deities[]`, `sections[]`, `titles`, `review_status` received (blocks DTO keys)
- [x] `ILSutraDTO` / `ILSutraTranslationDTO`: add the new optional fields; `ILSutraMapper.toDetail` fills them
- [x] `ILSutraDetailSutraEntity`: add the new business fields (`ILSutraDetailEntity.swift`)
- [x] `ILSutraDetailStateModel`: `infoSections` (summary / info / translation & license / notice)
- [x] `ILSutraDetailViewModel`: format rows, drop empty values
- [x] `Views/ILSutraDetailInfoView` + ViewController: summary / info / license blocks, each hidden when empty;
      tappable `source_url` / `license_url` (`.openLink`)
- [x] Unit tests written: mapper (new fields, missing → empty), ViewModel (sections, order, link event)
- [ ] Run the unit tests (needs a device / simulator destination)
- [x] Build verification (`generic/platform=iOS`) — BUILD SUCCEEDED 2026-10-11
- [ ] Update `InnerLamp/Presentation/Scenes/SutraDetail/README.md`; visual QA on device (long license note,
      empty summary, dark mode)

## Phase 4 — Download destination (pending, separate scope)

- [ ] Build the Download screen (`downloads`) and wire `.download` to it
- [ ] Update `InnerLamp/Presentation/Scenes/SutraDetail/README.md` (note: its
      `.openPlayer` "TODO" row is stale — `.openPlayer` is wired)

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/SutraDetail/README.md` (implementation
      notes, status table, changelog)
- [ ] `Docs/Knowledge/features/sutra-detail.md` (OKF concept) — hold off until
      the sutra API (Phase 3) lands. See `Docs/Specs/OKF.md`.

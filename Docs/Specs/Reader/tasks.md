# Tasks — Reader

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3–4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature has no network layer today; Phase 3 tracks replacing the
> static catalog with a real sutra API.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILReaderViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: header + "Aa", reading-progress bar,
      verse block + translation, share/download chips, next-verse preview,
      bottom playback bar — per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILReaderVerseView`, `ILReaderPlaybackBarView`
- [x] Add shared `ILPlayPauseButton` + `ILTypography.readerVerse` /
      `readerTranslation`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (block `isReader`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILReaderEntity` + `ILReaderSutraEntity` + `ILReaderVerseEntity`
- [x] Create `ILReaderStateModel`
- [x] Create `ILReaderUseCase` / `ILReaderUseCaseImpl` (catalog, currentSutra/
      Verse/nextVerse, togglePlayPause — pure logic)
- [x] Create `ILReaderViewModel` (`Input -> Output`, `ILReaderNavEvent`,
      `sutraID` parameter, time formatting)
- [x] Create `ILReaderCoordinator` (back pop+finish; `.openPlayer` → Player;
      other destinations TODO)
- [x] Wire `DIContainer.makeReaderUseCase/ViewModel/Coordinator`
- [x] Wire `ILLibraryCoordinator` (`openItem` with `kind == .sutra` → Reader)
- [x] Unit tests: `InnerLampTests/ILReaderViewModelTests.swift` (7 tests) —
      load sutra, toggle play, 5 nav events

## Phase 3 — API integration (pending; blocked on contract)

> ⚠️ Not confirmed: the sutra catalog / verse-content API contract(s) (see
> `requirements.md` Pending). Everything below is blocked until a contract
> exists.

- [ ] Define the sutra catalog / verse-content API contract(s) with the backend
      team
- [ ] Create `ILReaderDTO` + `ILReaderMapper` (once the contract is confirmed)
- [ ] Create `ReaderEndpoint` under `Data/DataSources/Remote/`
- [ ] Create `ILReaderRepository` protocol + `ILReaderRepositoryImpl` wrapping
      `NetworkService`
- [ ] Replace the static catalog in `ILReaderUseCaseImpl` with real data
- [ ] Wire real audio (`ILPracticeSoundPlayer`/AVAudioPlayer) with a recitation
      audio file
- [ ] Update `ILReaderViewModelTests` + add a mock repository
- [ ] Visual QA on simulator/device (scroll, playback bar, dark mode)
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Sub-destinations (pending, separate scope)

- [ ] Build the font-size setting screen and wire `.openFontSize`
- [ ] Build the Share screen and wire `.share`
- [ ] Build the offline-download screen and wire `.download`
- [ ] Wire the lib → `ILSutraDetailCoordinator` → Reader flow once
      `ILSutraDetailCoordinator` is built
- [ ] Update `InnerLamp/Presentation/Scenes/Reader/README.md` changelog

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Reader/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/reader.md` (OKF concept) — hold off until the
      sutra API (Phase 3) lands. See `Docs/Specs/OKF.md`.

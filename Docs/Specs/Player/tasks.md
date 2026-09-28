# Tasks — Player

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3–4 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature has no network or real audio today; Phase 3 tracks
> replacing the static catalog with a real track API + audio.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILPlayerViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: radial background, header + "Mục lục",
      artwork, title/subtitle, progress + times, seek + play/pause, speed row,
      sleep row + note — per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILPlayerArtworkView`, `ILPlayerOptionRowView`
- [x] Extend shared `ILPlayPauseButton` (`glyphColor`) +
      `ILImmersiveBackgroundView` (`.player` style) + add `ILPlayer*` tokens +
      `ILTypography.playerTitle`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `player`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILPlayerEntity` + `ILPlayerTrackEntity`
- [x] Create `ILPlayerStateModel`
- [x] Create `ILPlayerUseCase` / `ILPlayerUseCaseImpl` (catalog, togglePlayPause,
      rewind/forward, selectSpeed/selectSleepTimer — pure in-memory)
- [x] Create `ILPlayerViewModel` (`Input -> Output`, `ILPlayerNavEvent`,
      `sutraID` parameter, formatting)
- [x] Create `ILPlayerCoordinator` (leaf — `.back` pop+finish;
      `.openTableOfContents` TODO)
- [x] Wire `DIContainer.makePlayerUseCase/ViewModel/Coordinator`
- [x] Wire `ILReaderCoordinator` + `ILSutraDetailCoordinator` (`.openPlayer`)
- [x] Unit tests: `InnerLampTests/ILPlayerViewModelTests.swift` (8 tests)

## Phase 3 — API + audio (pending; blocked on contract)

> ⚠️ Not confirmed: the sutra-audio / track API contract(s) (see
> `requirements.md` Pending). Everything below is blocked until a contract
> exists.

- [ ] Define the sutra-audio / track API contract(s) with the backend team
- [ ] Create `ILPlayerDTO` + `ILPlayerMapper` (once the contract is confirmed)
- [ ] Create `PlayerEndpoint` under `Data/DataSources/Remote/`
- [ ] Create `ILPlayerRepository` protocol + implementation wrapping
      `NetworkService`
- [ ] Replace the static catalog in `ILPlayerUseCaseImpl` with real data
- [ ] Wire real audio (`AVAudioPlayer` / shared audio service) to play/pause/seek
- [ ] Update `ILPlayerViewModelTests` + add a mock repository
- [ ] Visual QA on simulator/device (layout, dark mode)
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Table of contents (pending, separate scope)

- [ ] Decide and wire the "Mục lục" destination (open the chapter list /
      SutraDetail from the player)
- [ ] Update `InnerLamp/Presentation/Scenes/Player/README.md` changelog

## Phase 5 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Player/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/player.md` (OKF concept) — hold off until the
      track API (Phase 3) lands. See `Docs/Specs/OKF.md`.

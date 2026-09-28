# Tasks — Talk

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILTalkViewController` extending `BaseViewController`
- [ ] `setupViews()`: transparent hero header, title/speaker/duration, player
      controls (play/pause, ±15s/±30s, seek), chapter list, follow-up card
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire playback controls / chapter taps / follow-up tap
      to `Input`, render `Output.state`
- [ ] Visual QA against the design prototype (screen `talk`)

## Phase 2 — Logic (Domain + real behavior)

- [ ] Create `ILTalkEntity` + `ILTalkChapterEntity` (pure business fields)
- [ ] Create `ILTalkStateModel` (UI state, no UIKit import)
- [ ] Create `ILTalkUseCase` / `ILTalkUseCaseImpl`:
      - `getTalk(id:)` — stub only (no confirmed backend contract)
      - `ILTalkError`
- [ ] Create `ILTalkViewModel` (`Input -> Output`, `ILTalkNavEvent`)
- [ ] Create `ILTalkCoordinator` + delegate protocol
- [ ] Wire `DIContainer.makeTalk{UseCase,ViewModel,Coordinator}`
- [ ] Wire `LibraryCoordinator.showTalk(id:)` + delegate conformance
- [ ] Unit tests: `ILTalkViewModelTests.swift` (mock UseCase)

## Phase 3 — API integration (pending, blocks feature completion)

> Contracts unconfirmed (see `requirements.md` Pending ⚠️).

- [ ] Define the talk-detail API contract (endpoint, response shape, chapters,
      error cases)
- [ ] Resolve the audio-source question (stream URL vs download vs DRM)
- [ ] Create `ILTalkDTO` + `ILTalkMapper` (only after contracts confirmed)
- [ ] Create the `Endpoint` conformance under `Data/DataSources/Remote/`
- [ ] Create `ILTalkRepository` protocol + `ILTalkRepositoryImpl`
- [ ] Inject the repository into `ILTalkUseCaseImpl.init`; replace the stub
- [ ] Map network/HTTP errors to `ILTalkError` cases
- [ ] Update `ILTalkViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Talk/README.md`
- [ ] `Docs/Knowledge/features/talk.md` (OKF concept) — after Phase 3 lands

## Deferred (separate feature, not blocking Talk)

- Full-screen Player (speed / sleep timer), MeditationSetup, Reader.

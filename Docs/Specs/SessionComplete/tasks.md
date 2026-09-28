# Tasks — SessionComplete

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILSessionCompleteViewController` extending `BaseViewController`
- [ ] `setupViews()`: completion title, 3 stats, 4 mood chips, dedication row,
      bottom actions ("Ghi vào nhật ký" / "Để sau")
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire mood taps / save / skip to `Input`, render
      `Output.state`
- [ ] Visual QA against the design prototype (screen `done`)

## Phase 2 — Logic (Domain + real behavior)

- [ ] Create `ILSessionCompleteEntity` (pure business fields only)
- [ ] Create `ILSessionCompleteStateModel` (UI state, no UIKit import)
- [ ] Create `ILSessionCompleteUseCase` / `ILSessionCompleteUseCaseImpl`:
      - mood selection rules
      - `saveSession(...)` — stub only (persistence source unconfirmed)
- [ ] Create `ILSessionCompleteViewModel` (`Input -> Output`,
      `ILSessionCompleteNavEvent`)
- [ ] Create `ILSessionCompleteCoordinator` + delegate protocol
- [ ] Wire `DIContainer.makeSessionComplete{UseCase,ViewModel,Coordinator}`
- [ ] Wire `MeditationSessionCoordinator.showSessionComplete(...)` + delegate
      conformance
- [ ] Unit tests: `ILSessionCompleteViewModelTests.swift` (mock UseCase)

## Phase 3 — API / persistence integration (pending, blocks feature completion)

> Persistence model unconfirmed (see `requirements.md` Pending ⚠️).

- [ ] Confirm local-first vs backend recording and its contract
- [ ] Create `ILSessionCompleteRepository` protocol + `ILSessionCompleteRepositoryImpl`
      (local store and/or network)
- [ ] Create DTO + Mapper (only if a backend contract is confirmed)
- [ ] Inject the repository into `ILSessionCompleteUseCaseImpl.init`; replace the stub
- [ ] Map errors to feature error cases
- [ ] Update `ILSessionCompleteViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available (if applicable)

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/SessionComplete/README.md`
- [ ] `Docs/Knowledge/features/session-complete.md` (OKF concept) — after Phase 3

## Deferred (separate feature, not blocking SessionComplete)

- MeditationSession, Journal (write).

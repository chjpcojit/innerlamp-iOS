# Tasks — Awards

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective

> See `changelog.md` in this folder for the version history of this spec.

## Phase 1 — UI (static layout, mock state)

- [ ] Create `ILAwardsViewController` extending `BaseViewController`
- [ ] `setupViews()`: header, recent-badge card, 3-column badge grid, fixed
      bottom "Xem tiến trình tu tập" button
- [ ] `setupConstraints()`: Auto Layout per design tokens
- [ ] `bindViewModel()`: wire bottom button / back to `Input`, render
      `Output.state`
- [ ] Visual QA against the design prototype (screen `awards`)

## Phase 2 — Logic (Domain + real behavior)

- [ ] Create `ILAwardsEntity` (pure business fields only)
- [ ] Create `ILAwardsStateModel` (UI state, no UIKit import)
- [ ] Create `ILAwardsUseCase` / `ILAwardsUseCaseImpl`:
      - `loadAwards()` — stub only (source unconfirmed)
      - progress subtitle formatting
- [ ] Create `ILAwardsViewModel` (`Input -> Output`, `ILAwardsNavEvent`)
- [ ] Create `ILAwardsCoordinator` + delegate protocol
- [ ] Wire `DIContainer.makeAwards{UseCase,ViewModel,Coordinator}`
- [ ] Wire `ProfileCoordinator.showAwards()` + delegate conformance
- [ ] Unit tests: `ILAwardsViewModelTests.swift` (mock UseCase)

## Phase 3 — API / data integration (pending, blocks feature completion)

> Source unconfirmed (see `requirements.md` Pending ⚠️).

- [ ] Confirm badge/progress source (local computation vs backend) and contract
- [ ] Create `ILAwardsRepository` protocol + `ILAwardsRepositoryImpl`
- [ ] Create DTO + Mapper (only if a backend contract is confirmed)
- [ ] Inject the repository into `ILAwardsUseCaseImpl.init`; replace the stub
- [ ] Map errors to feature error cases
- [ ] Update `ILAwardsViewModelTests` + add a mock repository
- [ ] Manual test against a real/staging backend once available (if applicable)

## Phase 4 — Documentation

- [ ] `InnerLamp/Presentation/Scenes/Awards/README.md`
- [ ] `Docs/Knowledge/features/awards.md` (OKF concept) — after Phase 3

## Deferred (separate feature, not blocking Awards)

- Profile, Stats.

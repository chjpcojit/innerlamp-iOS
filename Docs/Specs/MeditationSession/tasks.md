# Tasks — MeditationSession

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1–2 done; Phase 3 pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature has no confirmed network layer; Phase 3 tracks replacing
> the `recordSession` stub with a real practice-log persistence.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILMeditationSessionViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: immersive background, `ILNavBar`,
      `ILBreathingRingView` + countdown, cue labels, transport controls,
      end-early link — per design handoff
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Add shared `ILBreathingRingView` (Reduce Motion aware) +
      `ILImmersiveTransportControlsView`
- [x] Add tokens (`medRing`, `medHalo`, `immersiveTimer`, `breathingRing*`, …)
- [x] Keep screen awake while visible
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `session`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILMeditationSessionEntity` + `ILBreathPhase`
- [x] Create `ILMeditationSessionStateModel`
- [x] Create `ILMeditationSessionUseCase` / `ILMeditationSessionUseCaseImpl`
      (`makeSession`, `tick`, `togglePause`, `endSession` real; `recordSession`
      stub)
- [x] Create `ILMeditationSessionViewModel` (`Input -> Output`,
      `ILMeditationSessionNavEvent`, injected 1s `ticker`, opening/closing bells)
- [x] Create `ILMeditationSessionCoordinator` + `ILMeditationSessionCoordinatorDelegate`
- [x] Wire `DIContainer.makeMeditationSessionUseCase/ViewModel/Coordinator`
- [x] Wire `ILMeditationSetupCoordinator` to start it on `.startSession`
- [x] Unit tests: `ILMeditationSessionViewModelTests` (11) +
      `ILMeditationSessionUseCaseTests` (8, in the same file)

## Phase 3 — Practice-log persistence (pending; blocked on storage decision)

> ⚠️ Not confirmed: the practice-log storage (local Core Data/UserDefaults vs
> backend metrics API) — see `requirements.md` Pending.

- [ ] Decide the practice-log storage and define the contract if remote
- [ ] Create `ILMeditationSessionRepository` protocol + implementation
- [ ] Replace the `recordSession` stub body with the real call (inject the
      repository into `ILMeditationSessionUseCaseImpl`)
- [ ] Update `ILMeditationSessionViewModelTests` + add a mock repository

## Phase 4 — Done screen & audio extras (pending, separate scope)

- [ ] Build the Done ("Hoàn thành") / Journal screen and wire `.finished`
      (currently a `print` TODO + dismiss in `ILMeditationSetupCoordinator`)
- [ ] Schedule the "3 tiếng khánh" opening/closing bells and the interval bell
- [ ] Add background-sound / voice guidance audio if in scope
- [ ] Consider wall-clock (`Date`)-based elapsed time for locked-screen sits
- [x] `InnerLamp/Presentation/Scenes/MeditationSession/README.md` (implementation
      notes, status table, changelog)
- [ ] `Docs/Knowledge/features/meditation-session.md` (OKF concept) — see
      `Docs/Specs/OKF.md`

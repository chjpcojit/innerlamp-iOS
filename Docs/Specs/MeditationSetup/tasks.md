# Tasks — MeditationSetup

Version: 1.0
Last updated: 2026-09-27
Status: complete (Phase 1–2); Done/Journal and extras pending

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature has no network layer; there is no Phase 3 (API).

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILMeditationSetupViewController` extending `BaseViewController`
- [x] `setupViews()`/`setupConstraints()`: gradient background, `ILNavBar` (✕),
      duration selector, bell card (3 static rows), tip card, footer CTA — per
      design handoff
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state`
- [x] Extract feature-scoped views: `ILMeditationSetupDurationView`,
      `ILMeditationSetupBellCardView`, `ILMeditationSetupTipView`
- [x] Add `ILTypography.optionChip`
- [x] Visual QA against `InnerLamp Prototype.dc.html` (screen `setup`)

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILMeditationSetupEntity` (`durationOptions` + `durationMinutes`)
- [x] Create `ILMeditationSetupStateModel`
- [x] Create `ILMeditationSetupUseCase` / `ILMeditationSetupUseCaseImpl`
      (getInitialState, selectDuration — pure logic)
- [x] Create `ILMeditationSetupViewModel` (`Input -> Output`,
      `ILMeditationSetupNavEvent`)
- [x] Create `ILMeditationSetupCoordinator` (full-screen modal; `.startSession`
      → `ILMeditationSessionCoordinator`; `.close` → dismiss+finish; conforms to
      `ILMeditationSessionCoordinatorDelegate`)
- [x] Wire `DIContainer.makeMeditationSetupUseCase/ViewModel/Coordinator`
- [x] Wire `ILMainTabCoordinator.onLampTapped` → `showMeditationSetup()`
- [x] Wire `ILHomeCoordinator.showMeditationSetup()` via
      `ILHomeNavEvent.openMeditationSetup`
- [x] Unit tests: `ILMeditationSetupViewModelTests` (6) +
      `ILMeditationSetupUseCaseTests` (4, in the same file)

## Phase 3 — API integration

Not applicable — no network call exists in this feature.

## Phase 4 — Done/Journal + extras (pending)

- [ ] Build the Done / Journal screen and wire `meditationSessionDidFinish`
      (currently a `print` TODO + closeFlow)
- [ ] Persist the selected duration (UserDefaults) instead of resetting to 20
- [ ] Decide whether bell/sound selection is in scope (see ⚠️ in
      `requirements.md`)
- [ ] Pass the Home suggested-session row content (title/teacher/duration) into
      the screen when opened from Home
- [x] `InnerLamp/Presentation/Scenes/MeditationSetup/README.md` (implementation
      notes, status table, changelog)
- [ ] `Docs/Knowledge/features/meditation-setup.md` (OKF concept) — see
      `Docs/Specs/OKF.md`

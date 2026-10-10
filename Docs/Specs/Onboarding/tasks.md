# Tasks — Onboarding

Version: 1.0
Last updated: 2026-09-27
Status: complete — all phases implemented (no network, no pending API)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature is fully implemented end to end. No Phase 3 (API) exists
> because there is no network call — persistence is local.

## Phase 1 — UI (static layout, mock state)

- [x] Create `ILOnboardingViewController` extending `BaseViewController`
- [x] `setupViews()`: gradient background, logo/top bar + skip button,
      `ILStepProgressBar`, dynamically-built `stepViews` (intro / choice /
      toggle-list), bottom CTA + back button
- [x] `setupConstraints()`: steps pinned to the step container, bottom stack
      pinned to safe area, per design handoff tokens
- [x] `bindViewModel()`: wire UI actions to `Input` subjects, render
      `Output.state` via `render(state:)`
- [x] Add the interactive swipe-to-change-step gesture (UIPanGestureRecognizer
      driving a paused `UIViewPropertyAnimator`), with `suppressNextRenderAnimation`
      to avoid double-animating
- [x] Add feature-scoped step views: `ILOnboardingIntroStepView`,
      `ILOnboardingChoiceStepView`, `ILOnboardingToggleListStepView`
- [x] Visual QA against `InnerLamp Prototype.dc.html`

## Phase 2 — Logic (Domain + real behavior)

- [x] Create `ILOnboardingModel.swift` (`ILOnboardingStateModel`,
      `ILOnboardingStepContent`, `ILOnboardingIntentItem`, `ILOnboardingBellItem`)
- [x] Create `ILOnboardingUseCase` / `ILOnboardingUseCaseImpl`:
      - `getInitialState()`
      - `savePreferences(state:)` (persists intents/bells via `UserDefaultsService`)
      - `markOnboardingCompleted()` / `isOnboardingCompleted()`
- [x] Create `ILOnboardingViewModel` (`Input -> Output`, `ILOnboardingNavEvent`,
      `navigationEventPublisher`)
- [x] Create `ILOnboardingCoordinator` + `ILOnboardingCoordinatorDelegate`
- [x] Wire `DIContainer.makeOnboardingUseCase/ViewModel/Coordinator`
- [x] Wire `AppCoordinator.showOnboarding()` + conform to
      `ILOnboardingCoordinatorDelegate`
- [x] Unit tests: `InnerLampTests/ILOnboardingViewModelTests.swift` (7 tests,
      driven via `Input` publishers, `MockILOnboardingUseCase`) — covering
      initial state, next-through-all-steps-and-complete, back-to-login,
      back-within-steps, skip, toggle intent, toggle bell

## Phase 3 — API integration

Not applicable — no network call exists in this feature. Persistence is local
(`UserDefaultsService`).

## Phase 4 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Onboarding/README.md` (implementation
      notes, status table, changelog)
- [ ] `Docs/Knowledge/features/onboarding.md` (OKF concept) — see
      `Docs/Specs/OKF.md`; the concept is listed as "not yet written" there and
      is a separate `okf-writer` task.

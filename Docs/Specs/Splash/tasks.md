# Tasks — Splash

Version: 1.0
Last updated: 2026-09-27
Status: in-progress (Phase 1 done; Phase 2 routing item pending)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature has no network layer; Phases here reflect UI/branding vs.
> routing logic rather than API integration.

## Phase 1 — UI (branding screen)

- [x] Create `ILSplashViewController` extending `BaseViewController`
- [x] `setupViews()`: backdrop, ambience, lamp glow, ember field, wordmark,
      tagline, pulsing dots — in the design's paint order
- [x] `setupConstraints()`: centered column guide, height-ratio anchored
      ambience, per design handoff tokens
- [x] Branding animation: backdrop glow, ripple/rays, lamp ignite + flicker,
      ember field, wordmark reveal, tagline rise, dots pulse (started in
      `viewDidAppear`)
- [x] Light/dark theming via `--il-spl-*` token family + `traitCollectionDidChange`
- [x] Extract/reuse shared components (`ILLampGlowView` `.splash`,
      `ILFlameView`, `ILLoadingDotsView`) and feature views
      (`ILSplashBrandBackdropView`, `ILSplashAmbienceView`,
      `ILSplashEmberFieldView`, `ILSplashWordmarkLabel`,
      `ILSplashLoadingIndicatorView`)
- [x] Visual QA against `InnerLamp Prototype.dc.html` (block `isSplash`) +
      the static launch screen (light/dark)

## Phase 2 — Logic (Domain + routing)

- [x] Create `ILSplashModel.swift` (`ILSplashStateModel` — empty marker)
- [x] Create `ILSplashUseCase` / `ILSplashUseCaseImpl` (`getInitialState()`,
      `isOnboardingCompleted()` delegating to `ILOnboardingUseCase`)
- [x] Create `ILSplashViewModel` (`Input -> Output`, `ILSplashNavEvent`,
      `navigationEventPublisher`)
- [x] Create `ILSplashCoordinator` + `ILSplashCoordinatorDelegate`
- [x] Wire `DIContainer.makeSplashUseCase/ViewModel/Coordinator`
- [x] Wire `AppCoordinator.start()` → `showSplash()` + conform to
      `ILSplashCoordinatorDelegate`
- [x] Unit tests: `InnerLampTests/ILSplashViewModelTests.swift` (2 tests) —
      initial state, `splashFinished` → `.goToOnboarding`
- [ ] Re-enable the real routing decision in `handleSplashFinished()` —
      `useCase.isOnboardingCompleted() ? .goToMain : .goToOnboarding` — once
      the product decision is made (see ⚠️ in `requirements.md` Pending)

## Phase 3 — API integration

Not applicable — no network call exists in this feature.

## Phase 4 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Splash/README.md` (implementation notes,
      status table, changelog)
- [ ] `Docs/Knowledge/features/splash.md` (OKF concept) — see
      `Docs/Specs/OKF.md`; the concept is listed as "not yet written" there and
      is a separate `il-okf-writer` task.

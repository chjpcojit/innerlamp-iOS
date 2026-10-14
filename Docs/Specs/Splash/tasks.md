# Tasks — Splash

Version: 1.6
Last updated: 2026-10-10
Status: done (new routing test written but not yet executed)

> See `changelog.md` in this folder for the version history of this spec.

> Note: this feature has no network layer; Phases here reflect UI/branding vs.
> routing logic rather than API integration.

## Phase 1 — UI (branding screen)

- [x] Create `ILSplashViewController` extending `BaseViewController`
- [x] `setupViews()`: backdrop, ambience, lamp glow, ember field, wordmark,
      tagline — in the design's paint order
- [x] `setupConstraints()`: centered column guide, height-ratio anchored
      ambience, per design handoff tokens
- [x] Branding animation: backdrop glow, ripple/rays, lamp ignite + flicker,
      ember field, wordmark reveal, tagline rise (started in
      `viewDidAppear`)
- [x] Light/dark theming via `--il-spl-*` token family + `traitCollectionDidChange`
- [x] Extract/reuse shared components (`ILLampGlowView` `.splash`,
      `ILFlameView`) and feature views
      (`ILSplashBrandBackdropView`, `ILSplashAmbienceView`,
      `ILSplashEmberFieldView`, `ILSplashWordmarkLabel`)
- [x] Visual QA against `InnerLamp Prototype.dc.html` (block `isSplash`) +
      the static launch screen (light/dark)

## Phase 2 — Logic (Domain + routing)

- [x] Create `ILSplashModel.swift` (`ILSplashStateModel` — empty marker)
- [x] Create `ILSplashUseCase` / `ILSplashUseCaseImpl` (`getInitialState()`,
      `isOnboardingCompleted()` delegating to `ILOnboardingUseCase`,
      `hasSession()` with fresh-install and legacy-credential cleanup)
- [x] Create `ILSplashViewModel` (`Input -> Output`, `ILSplashNavEvent`,
      `navigationEventPublisher`)
- [x] Create `ILSplashCoordinator` + `ILSplashCoordinatorDelegate`
- [x] Wire `DIContainer.makeSplashUseCase/ViewModel/Coordinator`
- [x] Wire `AppCoordinator.start()` → `showSplash()` + conform to
      `ILSplashCoordinatorDelegate`
- [x] Unit tests: `InnerLampTests/ILSplashViewModelTests.swift` (4 tests) —
      initial state, no session → `.goToOnboarding`, no session + onboarding
      completed → `.goToSignup`, stored session → `.goToMain` (written, not yet
      run: `xcodebuild test` is blocked by the GRPC plugin)
- [x] Route in `handleSplashFinished()` by `useCase.hasSession()`
      (`.goToMain` / `.goToOnboarding`)
- [x] Route users who completed onboarding but have no session to SignUp as the
      root screen, back button hidden (`.goToSignup`, `splashDidRequestSignup` →
      `showSignUp(asRoot: true)`)
- [x] Unit tests: `InnerLampTests/ILSplashUseCaseTests.swift` (4 tests) —
      fresh-install token wipe, session kept after first launch, legacy
      credential purge, no token → false (see `TD-Splash-001`)

## Phase 3 — API integration

Not applicable — no network call exists in this feature.

## Phase 4 — Documentation

- [x] `InnerLamp/Presentation/Scenes/Splash/README.md` (implementation notes,
      status table, changelog)
- [x] `Docs/Knowledge/features/splash.md` (OKF concept) — written and synced
      with the session-based routing on 2026-10-10

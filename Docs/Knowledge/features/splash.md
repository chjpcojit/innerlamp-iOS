---
type: Feature
title: Splash
description: Launch branding screen — plays the lamp-ignition animation with no user interaction, then auto-advances to the next screen; the post-splash route is temporarily hardcoded to Onboarding.
resource: InnerLamp/Presentation/Scenes/Splash/
tags: [launch, mvvm-c]
status: draft
generated: { by: claude-code, at: 2026-09-27T14:54:58+07:00 }
sources:
  - path: Docs/Specs/Splash/requirements.md
    kind: spec
  - path: Docs/Specs/Splash/design.md
    kind: spec
  - path: InnerLamp/Presentation/Scenes/Splash/ILSplashViewController.swift
    kind: code
  - path: InnerLamp/Domain/UseCases/Splash/ILSplashUseCase.swift
    kind: code
---

# Summary

Splash is the first screen on launch, owned top-level by `AppCoordinator`
(`start()` → `showSplash()`). It plays a pure branding animation — backdrop
glow, ambience ripple/rays, lamp ignite + flicker, ember field, wordmark reveal,
tagline rise, pulsing dots — with no user interaction, then auto-advances after
3.2s. There is no network and no dynamic content (`ILSplashStateModel` is an
empty marker struct).

The post-splash route is **temporarily hardcoded**: `handleSplashFinished()`
always emits `.goToOnboarding`; the `useCase.isOnboardingCompleted() ? .goToMain
: .goToOnboarding` branch is written but commented out with a "TEMP DEBUG —
revert" marker. Both destinations are fully wired, so only the ViewModel decision
is missing.

# Architecture

MVVM-C + Clean Architecture. `ILSplashCoordinator` is set as the root of its own
stack (`setViewControllers([...], animated: false)`).

> Architectural drift (documented faithfully): `ILSplashStateModel` lives in
> `Domain/Entities/ILSplashModel.swift` (Domain) rather than Presentation — the
> same pre-convention placement as Onboarding. It is an empty marker struct.

| Layer | Type | File |
|---|---|---|
| Domain / Model | Domain model | `Domain/Entities/ILSplashModel.swift` — `ILSplashStateModel` (empty marker) |
| Domain / UseCase | UseCase | `Domain/UseCases/Splash/ILSplashUseCase.swift` — `getInitialState()`, `isOnboardingCompleted()` (delegates to the injected `ILOnboardingUseCase`, no direct UserDefaults read) |
| Presentation / ViewModel | ViewModel | `Presentation/Scenes/Splash/ILSplashViewModel.swift` — `Input -> Output`; owns `ILSplashNavEvent` (`.goToOnboarding`, `.goToMain`) |
| Presentation / Coordinator | Coordinator | `Presentation/Scenes/Splash/ILSplashCoordinator.swift` — `setViewControllers`, forwards to `ILSplashCoordinatorDelegate` |
| Presentation / ViewController | ViewController | `Presentation/Scenes/Splash/ILSplashViewController.swift` — runs the animation and schedules auto-advance |
| Feature-scoped views | View | `Presentation/Scenes/Splash/Views/ILSplashBrandBackdropView.swift`, `ILSplashAmbienceView.swift`, `ILSplashEmberFieldView.swift`, `ILSplashWordmarkLabel.swift`, `ILSplashLoadingIndicatorView.swift` |
| Tests | Unit tests | `InnerLampTests/ILSplashViewModelTests.swift` (2 tests) |

Shared: `ILLampGlowView` (`.splash`), `ILFlameView`, `ILLoadingDotsView`,
`ILTypography` / `ILColors` / `ILMetrics`. Themed via the `--il-spl-*` token
family.

# Navigation

```
AppCoordinator
  └─ showSplash() → ILSplashCoordinator                 (owned top-level)
       setViewControllers([ILSplashViewController], animated: false)
       (auto-advance) → .goToOnboarding → showOnboarding()   [finish]
       (auto-advance) → .goToMain       → showMain()         [finish — wired but unused]
```

# Data flow (auto-advance)

`ILSplashViewController.viewDidAppear` starts the brand animation and calls
`scheduleAutoAdvance()` (3.2s); on elapse `splashFinishedSubject` fires and
`ILSplashViewModel.handleSplashFinished()` emits `.goToOnboarding` (hardcoded).

# Pending work

- The real routing decision is commented out in
  `ILSplashViewModel.handleSplashFinished()`.
  > ⚠️ Not confirmed: when to flip the branch to `isOnboardingCompleted()` — a
  > product decision (always route through Onboarding during development vs skip
  > to Main for already-onboarded users). Blocks `tasks.md` Phase 2.
- Promote to `stable` once the routing decision is re-enabled and the flow is
  exercised end-to-end.

# Related concepts

- [Onboarding](onboarding.md) (`InnerLamp/Presentation/Scenes/Onboarding/`) — the
  hardcoded destination; `isOnboardingCompleted()` is its UseCase's method.
- [Main](main.md) (`InnerLamp/Presentation/Scenes/Main/`) — the intended
  destination for already-onboarded users.

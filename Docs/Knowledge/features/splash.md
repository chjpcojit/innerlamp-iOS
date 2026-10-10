---
type: Feature
title: Splash
description: Launch branding screen — plays the lamp-ignition animation (no loading indicator, no user interaction), then auto-advances to Main when a Keychain session exists, to Login when there is no session but onboarding was completed, otherwise to Onboarding.
resource: InnerLamp/Presentation/Scenes/Splash/
tags: [launch, mvvm-c]
status: draft
generated: { by: claude-code, at: 2026-10-10T16:40:00+07:00 }
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
tagline rise — with no user interaction and no loading indicator (the pulsing-dots
row was removed to match the design handoff), then auto-advances after 3.2s.
There is no network and no dynamic content (`ILSplashStateModel` is an empty
marker struct).

The post-splash route is decided by `ILSplashViewModel.handleSplashFinished()`:
`hasSession()` → `.goToMain`; else `isOnboardingCompleted()` → `.goToLogin`; else
`.goToOnboarding`. `hasSession()` only checks
that an access token exists in the Keychain; it does not check expiry by design — an
expired token is refreshed automatically on the first 401 (`AuthSessionRefresher`), and
a failed refresh clears the session and routes to Login. On a fresh install (no
`has_launched_before` flag in UserDefaults) it first deletes any Keychain tokens
left over from a previous install, and on every launch it deletes the legacy
`signup_pending_credentials` Keychain item.

# Architecture

MVVM-C + Clean Architecture. `ILSplashCoordinator` is set as the root of its own
stack (`setViewControllers([...], animated: false)`).

> Architectural drift (documented faithfully): `ILSplashStateModel` lives in
> `Domain/Entities/ILSplashModel.swift` (Domain) rather than Presentation — the
> same pre-convention placement as Onboarding. It is an empty marker struct.

| Layer | Type | File |
|---|---|---|
| Domain / Model | Domain model | `Domain/Entities/ILSplashModel.swift` — `ILSplashStateModel` (empty marker) |
| Domain / UseCase | UseCase | `Domain/UseCases/Splash/ILSplashUseCase.swift` — `getInitialState()`, `isOnboardingCompleted()` (delegates to the injected `ILOnboardingUseCase`; picks Login vs Onboarding when there is no session), `hasSession()` (Keychain access-token check plus the fresh-install / legacy-credential cleanup above) |
| Presentation / ViewModel | ViewModel | `Presentation/Scenes/Splash/ILSplashViewModel.swift` — `Input -> Output`; owns `ILSplashNavEvent` (`.goToOnboarding`, `.goToLogin`, `.goToMain`) |
| Presentation / Coordinator | Coordinator | `Presentation/Scenes/Splash/ILSplashCoordinator.swift` — `setViewControllers`, forwards to `ILSplashCoordinatorDelegate` (3 methods) |
| Presentation / ViewController | ViewController | `Presentation/Scenes/Splash/ILSplashViewController.swift` — runs the animation and schedules auto-advance |
| Feature-scoped views | View | `Presentation/Scenes/Splash/Views/ILSplashBrandBackdropView.swift`, `ILSplashAmbienceView.swift`, `ILSplashEmberFieldView.swift`, `ILSplashWordmarkLabel.swift` |
| Tests | Unit tests | `InnerLampTests/ILSplashViewModelTests.swift` (4 tests: initial state, no session → `.goToOnboarding`, no session + onboarding completed → `.goToLogin`, stored session → `.goToMain`; the new one is written but not yet run — `xcodebuild test` is blocked by the GRPC plugin) |

Shared: `ILLampGlowView` (`.splash`), `ILFlameView`,
`ILTypography` / `ILColors` / `ILMetrics`. Themed via the `--il-spl-*` token
family.

# Navigation

```
AppCoordinator
  └─ showSplash() → ILSplashCoordinator                 (owned top-level)
       setViewControllers([ILSplashViewController], animated: false)
       (auto-advance) → .goToOnboarding → showOnboarding()   [finish — no session, onboarding not completed]
       (auto-advance) → .goToLogin      → showLogin()        [finish — no session, onboarding completed]
       (auto-advance) → .goToMain       → showMain()         [finish — stored session]
```

# Data flow (auto-advance)

`ILSplashViewController.viewDidAppear` starts the brand animation and calls
`scheduleAutoAdvance()` (3.2s); on elapse `splashFinishedSubject` fires and
`ILSplashViewModel.handleSplashFinished()` emits `.goToMain`, `.goToLogin` or `.goToOnboarding` (see above).

# Pending work

- Onboarding vs Login keys on the completed-onboarding flag, so a user who quits
  mid-Onboarding sees Onboarding again next launch
  (`Docs/Assumptions/Splash/AS-Splash-001`, validated).
- Kept `draft`: the stored-session → Main path has unit tests but has not been
  exercised end-to-end against a real backend session.

# Related concepts

- [Onboarding](onboarding.md) (`InnerLamp/Presentation/Scenes/Onboarding/`) — the
  destination when no Keychain session exists and onboarding is not completed.
- [Login](login.md) (`InnerLamp/Presentation/Scenes/Login/`) — the destination when
  no session exists but onboarding was completed.
- [Main](main.md) (`InnerLamp/Presentation/Scenes/Main/`) — the
  destination when a Keychain session exists.

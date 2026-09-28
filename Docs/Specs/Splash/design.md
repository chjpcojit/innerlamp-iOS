# Design — Splash

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — branding animation done; post-splash route hardcoded to
Onboarding

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Splash follows MVVM-C + Clean Architecture per `AGENTS.md`. It is the **first
screen** and is owned top-level by `AppCoordinator` (`start()` calls
`showSplash()`). It is a pure branding moment — no user interaction, no
network, no dynamic content. `ILSplashCoordinator` is set as the root of its
own stack with `setViewControllers([...], animated: false)`.

> Note (architectural drift): `ILSplashStateModel` lives in
> `Domain/Entities/ILSplashModel.swift` (Domain) rather than Presentation — the
> same pre-convention placement as Onboarding. It is an empty marker struct.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Model | `Domain/Entities/ILSplashModel.swift` | `ILSplashStateModel` — empty marker struct (Splash has no dynamic content). Foundation only. |
| Domain / UseCase | `Domain/UseCases/Splash/ILSplashUseCase.swift` | `getInitialState()` and `isOnboardingCompleted()` (delegates to the injected `ILOnboardingUseCase` — no direct UserDefaults read). |
| Presentation / ViewModel | `Presentation/Scenes/Splash/ILSplashViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILSplashNavEvent` (`.goToOnboarding`, `.goToMain`) and `navigationEventPublisher`. |
| Presentation / Coordinator | `Presentation/Scenes/Splash/ILSplashCoordinator.swift` | `setViewControllers`; forwards nav events to `ILSplashCoordinatorDelegate` (2 methods). |
| Presentation / ViewController | `Presentation/Scenes/Splash/ILSplashViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`; runs the branding animation and schedules auto-advance. |
| Feature-scoped views | `Presentation/Scenes/Splash/Views/ILSplashBrandBackdropView.swift`, `ILSplashAmbienceView.swift`, `ILSplashEmberFieldView.swift`, `ILSplashWordmarkLabel.swift`, `ILSplashLoadingIndicatorView.swift` | Splash-specific branding views, themed via the `--il-spl-*` token family. |

Shared (not owned by Splash): `ILLampGlowView` (`.splash` style),
`ILFlameView`, `ILLoadingDotsView`, `ILTypography` / `ILColors` / `ILMetrics`.

## Navigation flow

```
AppCoordinator
  └─ showSplash() → ILSplashCoordinator                  (owned top-level)
       setViewControllers([ILSplashViewController], animated: false)
       (auto-advance) → .goToOnboarding → showOnboarding()   [finish]
       (auto-advance) → .goToMain       → showMain()         [finish — reachable but unused]
```

## Data flow (auto-advance)

1. `ILSplashViewController.viewDidAppear` starts the brand animation and calls
   `scheduleAutoAdvance()` (3.2s).
2. On timer elapse, `splashFinishedSubject` fires.
3. `ILSplashViewModel.handleSplashFinished()` emits `.goToOnboarding` — see the
   routing gap below.

## Routing gap (temporarily hardcoded)

`ILSplashViewModel.handleSplashFinished()`:

```swift
navigationEventSubject.send(.goToOnboarding) // TEMP DEBUG — revert
```

The intended logic — `useCase.isOnboardingCompleted() ? .goToMain :
.goToOnboarding` — is present in the file but commented out. Both
`.goToMain` and `.goToOnboarding` are fully wired in the coordinator and
`AppCoordinator` (`splashDidRequestOnboarding` / `splashDidRequestMain`), so
only the ViewModel decision is missing. See the ⚠️ in `requirements.md` Pending.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
block `isSplash`. The static iOS launch screen (`Base.lproj/LaunchScreen.storyboard`)
follows the **system** appearance (no app-theme override can run that early),
matching `Docs/design_handoff_innerlamp/launch/README.md`. See
`InnerLamp/Presentation/Scenes/Splash/README.md` for the full
design-vs-implementation comparison and changelog.

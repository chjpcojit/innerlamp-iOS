# Design — Splash

Version: 1.6
Last updated: 2026-10-10
Status: implemented — branding animation and session-based routing done

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
| Domain / UseCase | `Domain/UseCases/Splash/ILSplashUseCase.swift` | `getInitialState()`; `isOnboardingCompleted()` (delegates to the injected `ILOnboardingUseCase`; picks SignUp vs Onboarding when there is no session); `hasSession()` — Keychain access-token existence check, plus the fresh-install and legacy-credential cleanup. Injects `ILOnboardingUseCase`, `KeychainService`, `UserDefaultsService`. |
| Presentation / ViewModel | `Presentation/Scenes/Splash/ILSplashViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILSplashNavEvent` (`.goToOnboarding`, `.goToSignup`, `.goToMain`) and `navigationEventPublisher`. |
| Presentation / Coordinator | `Presentation/Scenes/Splash/ILSplashCoordinator.swift` | `setViewControllers`; forwards nav events to `ILSplashCoordinatorDelegate` (3 methods). |
| Presentation / ViewController | `Presentation/Scenes/Splash/ILSplashViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`; runs the branding animation and schedules auto-advance. |
| Feature-scoped views | `Presentation/Scenes/Splash/Views/ILSplashBrandBackdropView.swift`, `ILSplashAmbienceView.swift`, `ILSplashEmberFieldView.swift`, `ILSplashWordmarkLabel.swift` | Splash-specific branding views, themed via the `--il-spl-*` token family. |

Shared (not owned by Splash): `ILLampGlowView` (`.splash` style),
`ILFlameView`, `ILTypography` / `ILColors` / `ILMetrics`.

## Navigation flow

```
AppCoordinator
  └─ showSplash() → ILSplashCoordinator                  (owned top-level)
       setViewControllers([ILSplashViewController], animated: false)
       (auto-advance) → .goToOnboarding → showOnboarding()   [finish — no session, onboarding not completed]
       (auto-advance) → .goToSignup     → showSignUp(asRoot: true) [finish — no session, onboarding completed]
       (auto-advance) → .goToMain       → showMain()         [finish — stored session]
```

## Data flow (auto-advance)

1. `ILSplashViewController.viewDidAppear` starts the brand animation and calls
   `scheduleAutoAdvance()` (3.2s).
2. On timer elapse, `splashFinishedSubject` fires.
3. `ILSplashViewModel.handleSplashFinished()` calls `useCase.hasSession()`, then
   `isOnboardingCompleted()` when there is no session, and emits `.goToMain`,
   `.goToSignup` or `.goToOnboarding` (see Routing decision below).

## Routing decision

`ILSplashViewModel.handleSplashFinished()`:

```swift
if useCase.hasSession() { .goToMain }
else if useCase.isOnboardingCompleted() { .goToSignup }
else { .goToOnboarding }
```

`hasSession()` is evaluated first on purpose: it performs the fresh-install
cleanup, and a reinstall also clears the onboarding flag (UserDefaults), so a
fresh install lands on Onboarding.

`ILSplashUseCaseImpl.hasSession()` runs three steps, in order, on every launch:

1. Delete the legacy Keychain item `signup_pending_credentials` (an old dev mock
   stored raw credentials there; Keychain survives updates and reinstalls).
2. Fresh-install guard: if UserDefaults has no `has_launched_before` flag, delete
   the Keychain access and refresh tokens, then set the flag (UserDefaults is
   wiped with the app, Keychain is not; see `Docs/Tech-Debt/Splash/TD-Splash-001`).
3. Return whether the Keychain access-token key exists.

Both nav events are wired in the coordinator and `AppCoordinator`
(`splashDidRequestOnboarding` / `splashDidRequestMain`).

### Known limitations

- Only token **existence** is checked, by design. An expired access token is
  recovered outside Splash: the 401 on the first authenticated request makes
  `NetworkServiceImpl` call `AuthSessionRefresher`; if the refresh fails the
  session is cleared and `AppCoordinator` routes to Login.
- Onboarding vs SignUp keys on the completed-onboarding flag. A user who quits
  mid-Onboarding sees Onboarding again on the next launch (`AS-Splash-001`).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
block `isSplash`. The static iOS launch screen (`Base.lproj/LaunchScreen.storyboard`)
follows the **system** appearance (no app-theme override can run that early),
matching `Docs/design_handoff_innerlamp/launch/README.md`. See
`InnerLamp/Presentation/Scenes/Splash/README.md` for the full
design-vs-implementation comparison and changelog.

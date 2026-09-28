---
type: Feature
title: Onboarding
description: First-launch 3-step flow (intro → practice intents → bell reminders) that captures the user's preferences into local UserDefaults and routes them to Sign Up or Login; no network involved.
resource: InnerLamp/Presentation/Scenes/Onboarding/
tags: [onboarding, mvvm-c]
status: stable
generated: { by: claude-code, at: 2026-09-27T14:54:58+07:00 }
sources:
  - path: Docs/Specs/Onboarding/requirements.md
    kind: spec
  - path: Docs/Specs/Onboarding/design.md
    kind: spec
  - path: InnerLamp/Presentation/Scenes/Onboarding/ILOnboardingCoordinator.swift
    kind: code
  - path: InnerLamp/Domain/UseCases/Onboarding/ILOnboardingUseCase.swift
    kind: code
  - path: InnerLamp/Domain/Entities/ILOnboardingModel.swift
    kind: code
---

# Summary

Onboarding is the first-launch walkthrough: three steps (intro → practice
intents → bell reminders) the user steps or swipes through, ending in Sign Up
(or Login via the first-step back control). Selecting intents/chips and bell
toggles is persisted locally via `UserDefaultsService` and the completion flag
(`has_completed_onboarding`) gates whether the next launch routes through
Onboarding or straight to Main.

This is a purely local feature — no network, no Repository/DTO/Mapper, and no
pending work. The spec records it as `implemented` / `complete`. `stable` here
reflects a fully-implemented, unit-tested (7 tests) local flow with no backend to
verify against; the human `verified:` attestation is still absent.

# Architecture

MVVM-C + Clean Architecture, and the canonical shape later auth screens copied.
Cross-section navigation (Splash → Onboarding → SignUp/Login), so
`ILOnboardingCoordinator` is owned by `AppCoordinator` (`showOnboarding()`) and
set as the **root of its own stack** via `setViewControllers`.

> Architectural drift (documented faithfully): `ILOnboardingStateModel` and
> `ILOnboardingStepContent` live in `Domain/Entities/ILOnboardingModel.swift` —
> Domain, not the Presentation layer the strict rules require for a StateModel.
> This predates the current convention; the ViewModel and ViewController import
> it from Domain.

| Layer | Type | File |
|---|---|---|
| Domain / Model | Domain model | `Domain/Entities/ILOnboardingModel.swift` — `ILOnboardingStateModel`, `ILOnboardingStepContent` (`.intro` / `.chipChoice` / `.toggleList`), `ILOnboardingIntentItem`, `ILOnboardingBellItem` |
| Domain / UseCase | UseCase | `Domain/UseCases/Onboarding/ILOnboardingUseCase.swift` — `getInitialState()`, `savePreferences(state:)`, `markOnboardingCompleted()`, `isOnboardingCompleted()`; no network |
| Presentation / ViewModel | ViewModel | `Presentation/Scenes/Onboarding/ILOnboardingViewModel.swift` — `Input -> Output`; owns `ILOnboardingNavEvent` (`.goToSignup`, `.goToLogin`) |
| Presentation / Coordinator | Coordinator | `Presentation/Scenes/Onboarding/ILOnboardingCoordinator.swift` — `setViewControllers([ILOnboardingViewController])` |
| Presentation / ViewController | ViewController | `Presentation/Scenes/Onboarding/ILOnboardingViewController.swift` — adds an interactive swipe-to-change-step gesture |
| Feature-scoped views | View | `Presentation/Scenes/Onboarding/Views/ILOnboardingIntroStepView.swift`, `ILOnboardingChoiceStepView.swift`, `ILOnboardingToggleListStepView.swift` |
| Tests | Unit tests | `InnerLampTests/ILOnboardingViewModelTests.swift` (7 tests) |

Shared: `ILStepProgressBar`, `ILButton`, `ILTypography` / `ILColors` /
`ILMetrics`.

# Navigation

```
AppCoordinator
  ├─ showOnboarding() → ILOnboardingCoordinator           (owned by AppCoordinator)
  │    setViewControllers([ILOnboardingViewController])     ← root of its own stack
  │    (Next on last step / Skip) → .goToSignup → showSignUp()   [no finish — pushed]
  │    (Back on first step)       → .goToLogin  → showLogin()    [finish]
```

Entry point: `Splash` → `splashDidRequestOnboarding` → `showOnboarding()` on
first launch (when `isOnboardingCompleted()` is false).

# Local persistence (no network)

`ILOnboardingUseCaseImpl` injects `UserDefaultsService` and persists under three
keys — no Repository, no DTO, no Endpoint:

- `has_completed_onboarding` (Bool) — gates Splash's route to Onboarding vs Main.
- `onboarding_selected_intents` ([Int]) — selected practice intent ids.
- `onboarding_enabled_bells` ([Int]) — enabled bell reminder ids.

`isOnboardingCompleted()` is consumed by `ILSplashUseCase` to decide the
post-splash route.

# Pending work

None. The feature is fully implemented end to end (the spec has no open ⚠️ and no
pending API; there is no network call to complete).

# Related concepts

- [Splash](splash.md) (`InnerLamp/Presentation/Scenes/Splash/`) — routes here on
  first launch; reads `isOnboardingCompleted()`.
- [Sign Up](signup.md) (`InnerLamp/Presentation/Scenes/SignUp/`) — reached by the
  last-step CTA / "Bỏ qua".
- [Login](login.md) (`InnerLamp/Presentation/Scenes/Login/`) — reached by the
  first-step back control.
- [Main](main.md) (`InnerLamp/Presentation/Scenes/Main/`) — the post-auth shell
  Onboarding skips to once `has_completed_onboarding` is true.

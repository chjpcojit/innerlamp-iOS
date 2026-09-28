# Design — Onboarding

Version: 1.0
Last updated: 2026-09-27
Status: implemented — full flow with local persistence; no network

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Onboarding follows MVVM-C + Clean Architecture per `AGENTS.md`, and is the
canonical shape most later auth screens copied. It is a **cross-section
navigation** (Splash → Onboarding → SignUp / Login), so
`ILOnboardingCoordinator` is owned and wired by `AppCoordinator` (via
`showOnboarding()`). It is set as the **root of its own stack** with
`setViewControllers`. There is no network layer — preference persistence is
local (`UserDefaultsService`), so there is no Repository/DTO/Mapper.

> Note (architectural drift): `ILOnboardingStateModel` and
> `ILOnboardingStepContent` live in `Domain/Entities/ILOnboardingModel.swift`
> — i.e. in Domain rather than the Presentation layer the strict rules require
> for a StateModel. This predates the current convention and is documented
> faithfully here; the ViewModel and ViewController import it from Domain.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Model | `Domain/Entities/ILOnboardingModel.swift` | `ILOnboardingStateModel` (currentStep, steps, derived `ctaTitle`/`backTitle`/`intents`/`bells`/`isLastStep`, `togglingItem(atStep:itemIndex:)`), `ILOnboardingStepContent` (`.intro` / `.chipChoice` / `.toggleList`), `ILOnboardingIntentItem`, `ILOnboardingBellItem`. Pure value types, Foundation only. |
| Domain / UseCase | `Domain/UseCases/Onboarding/ILOnboardingUseCase.swift` | `getInitialState()`, `savePreferences(state:)` (writes selected intent ids + enabled bell ids to `UserDefaultsService`, then marks complete), `markOnboardingCompleted()`, `isOnboardingCompleted()`. No network. |
| Presentation / ViewModel | `Presentation/Scenes/Onboarding/ILOnboardingViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILOnboardingNavEvent` (`.goToSignup`, `.goToLogin`) and `navigationEventPublisher`. |
| Presentation / Coordinator | `Presentation/Scenes/Onboarding/ILOnboardingCoordinator.swift` | `setViewControllers([ILOnboardingViewController])`; forwards nav events to `ILOnboardingCoordinatorDelegate` (2 methods). |
| Presentation / ViewController | `Presentation/Scenes/Onboarding/ILOnboardingViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`; adds an interactive swipe-to-change-step gesture on top of the tap flow. |
| Feature-scoped views | `Presentation/Scenes/Onboarding/Views/ILOnboardingIntroStepView.swift`, `ILOnboardingChoiceStepView.swift`, `ILOnboardingToggleListStepView.swift` | One view per `ILOnboardingStepContent` case; each `onToggleItem` forwards to `toggleItemSubject`. |

Shared (not owned by Onboarding): `ILStepProgressBar`, `ILButton`,
`ILTypography` / `ILColors` / `ILMetrics`.

## Navigation flow

```
AppCoordinator
  ├─ showOnboarding() → ILOnboardingCoordinator          (owned by AppCoordinator)
  │    setViewControllers([ILOnboardingViewController])    ← root of its own stack
  │    (Next on last step / Skip) → .goToSignup → showSignUp()   [no finish — pushed]
  │    (Back on first step)       → .goToLogin  → showLogin()    [finish]
```

Entry point: `Splash` → `splashDidRequestOnboarding` → `showOnboarding()` on
first launch (when `isOnboardingCompleted()` is false).

## Data flow (step progression)

1. `ILOnboardingViewController` sends `nextTrigger`/`backTrigger`/`skipTrigger`/
   `toggleItem` to the ViewModel via `Input` subjects (or from the swipe
   gesture's completion).
2. `ILOnboardingViewModel.handleNext()`: advance `currentStep` unless already on
   the last step, in which case `useCase.savePreferences(state:)` then emit
   `.goToSignup`.
3. `handleBack()`: decrement `currentStep` unless on step 0, in which case emit
   `.goToLogin`.
4. `handleSkip()`: `useCase.savePreferences(state:)` then emit `.goToSignup`.
5. `handleToggleItem(stepIndex:itemIndex:)`: produce a new state via
   `currentState.togglingItem(atStep:itemIndex:)`.
6. `ILOnboardingUseCaseImpl.savePreferences` writes the selected intent ids and
   enabled bell ids to `UserDefaultsService`, then `markOnboardingCompleted()`
   (`has_completed_onboarding = true`).

## Local persistence (no network)

`ILOnboardingUseCaseImpl` injects `UserDefaultsService` and persists under
three keys — no Repository, no DTO, no Endpoint:

- `has_completed_onboarding` (Bool) — gates whether Splash routes to Onboarding
  or Main on next launch.
- `onboarding_selected_intents` ([Int]) — selected practice intent ids.
- `onboarding_enabled_bells` ([Int]) — enabled bell reminder ids.

`isOnboardingCompleted()` is consumed by `ILSplashUseCase` to decide the
post-splash route.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
the onboarding intro/step blocks. See `InnerLamp/Presentation/Scenes/Onboarding/
README.md` for the full design-vs-implementation comparison and changelog.

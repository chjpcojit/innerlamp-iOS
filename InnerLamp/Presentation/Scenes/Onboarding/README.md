# Onboarding

<!--
Generated/maintained via ui-builder. This is a living status doc for this screen, not a
one-time scaffold artifact — update it (don't recreate it) whenever this feature's files change:
a stub gets a real implementation, a new action/nav event is added, tests are filled in, etc.
Its job is so anyone (including future-you) can tell what's actually done here vs. still a
skeleton, without re-reading every file.
-->

## Overview

3-step onboarding flow (intro → practice intents → bell reminders) shown right after Splash on
first launch. Owned by `AppCoordinator` (major/cross-section flow — see
`references/coordinator_navigation_rules.md`): `ILSplashCoordinator` leads into it, and it leads
either to `ILSignUpCoordinator` (Next/Skip on the last step) or back to `ILLoginCoordinator`
(Back on the first step).

## Status

| Layer | File | Status | Notes |
|---|---|---|---|
| Domain — Entity | `ILOnboardingModel.swift` | Done | `ILOnboardingStateModel` + `ILOnboardingStepContent` (`.intro`/`.chipChoice`/`.toggleList`), `ILOnboardingIntentItem`, `ILOnboardingBellItem` |
| Domain — UseCase | `ILOnboardingUseCase.swift` | Done | All 4 methods real: `getInitialState`, `savePreferences` (persists selected intents/bells via `UserDefaultsService`), `markOnboardingCompleted`, `isOnboardingCompleted` — no network involved, nothing left as a TODO stub |
| Presentation — ViewModel | `ILOnboardingViewModel.swift` | Done | Combine `Input`/`Output` per `references/mvvm_pattern.md`; all 5 actions implemented (`viewDidLoad`, `nextTrigger`, `backTrigger`, `skipTrigger`, `toggleItem`) |
| Presentation — ViewController | `ILOnboardingViewController.swift` | Done | Full UI built, design-token compliant (no hardcoded text/font/color); adds an interactive swipe-to-change-step gesture on top of the standard tap flow |
| Presentation — Coordinator | `ILOnboardingCoordinator.swift` | Done | Both `ILOnboardingNavEvent` cases wired via `navigationEventPublisher` |
| Tests | `ILOnboardingViewModelTests.swift` | Done | 7 real tests covering initial state, next-through-all-steps-and-complete, back-to-login, back-within-steps, skip, toggle intent, toggle bell |
| Wiring | `DIContainer` + parent coordinator | Done | `AppCoordinator.showOnboarding()`, conforms to `ILOnboardingCoordinatorDelegate` |

## Navigation events

- `.goToSignup` — last step's Next tap, or Skip at any step. Coordinator does **not** call
  `finish()` here: SignUp is pushed on top (stack unchanged), so this coordinator must stay alive
  to keep receiving events if the user navigates back to Onboarding.
- `.goToLogin` — Back tap on the first step. Coordinator calls `finish()` here since Login replaces
  the whole nav stack.

## Known gaps / not implemented yet

Nothing outstanding — this screen is fully implemented end to end.

## Changelog

- 2026-09-12 — initial scaffold (closure-based ViewModel, unprefixed types)
- 2026-09-14 — migrated to the current ui-builder conventions: `IL`-prefixed types
  throughout (`ILOnboardingStateModel`, `ILOnboardingUseCase`, `ILOnboardingViewModel`,
  `ILOnboardingCoordinator`, `ILOnboardingIntroStepView`/`ILOnboardingChoiceStepView`/
  `ILOnboardingToggleListStepView`), ViewModel rewritten from closure-callback (`onState:`/
  `onNavigationEvent`) to Combine `Input`/`Output` + `navigationEventPublisher`, ViewModel tests
  migrated to drive actions through `Input` publishers instead of calling `handle*()` directly,
  `DIContainer`/`AppCoordinator`/`ILSplashUseCase` updated to the new type names

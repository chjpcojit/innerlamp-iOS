---
type: Feature
title: Main
description: Post-auth container — a 4-tab bar (Home / Library / Sangha / Me) with a central lamp action that opens the meditation-setup modal; owns no Entity/UseCase/ViewModel and no network.
resource: InnerLamp/Presentation/Scenes/Main/
tags: [navigation, mvvm-c]
status: stable
generated: { by: claude-code, at: 2026-09-27T14:54:58+07:00 }
sources:
  - path: Docs/Specs/Main/requirements.md
    kind: spec
  - path: Docs/Specs/Main/design.md
    kind: spec
  - path: InnerLamp/Presentation/Scenes/Main/ILMainTabCoordinator.swift
    kind: code
  - path: InnerLamp/Presentation/Scenes/Main/ILMainTabBarController.swift
    kind: code
---

# Summary

Main is the post-auth shell: a bottom tab bar with four tabs in order — Home,
Library, Sangha, Me — plus a prominent central lamp button that presents the
meditation-setup screen as a full-screen modal. It is a container/coordinator
feature, not a screen: it owns no Entity, UseCase, ViewModel, or StateModel and
has no network. It is reached from Login success, guest preview, OTP verify, and
(eventually) Splash.

`ILMainTabCoordinator` owns `ILMainTabBarController` and one child coordinator
per tab, each on its own `BaseNavigationController`. The native `UITabBar` is
hidden behind an `ILBottomNavBar` overlay; tab switching still routes through
`UITabBarController`, inheriting `BaseTabBarController`'s crossfade. The lamp
button is an **action**, not a fifth tab. The spec records Main as
`implemented` / `complete`; `stable` here reflects a complete local container
with no backend to verify against (the human `verified:` attestation is still
absent).

# Architecture

| Layer | Type | File |
|---|---|---|
| Presentation / Coordinator | Coordinator | `Presentation/Scenes/Main/ILMainTabCoordinator.swift` — owns the tab bar + four tab coordinators; wires `onLampTapped` → `showMeditationSetup()` |
| Presentation / ViewController | ViewController | `Presentation/Scenes/Main/ILMainTabBarController.swift` — `BaseTabBarController` subclass; hides native `UITabBar`, overlays `ILBottomNavBar`, syncs `activeTab`, `setBottomNavHidden(_:animated:)` |
| Presentation / ViewController | ViewController (unused) | `Presentation/Scenes/Main/ILTabPlaceholderViewController.swift` — superseded by real coordinators; can be deleted |

No Domain layer, no Data layer, no StateModel, no network.

# Tab wiring

`ILMainTabBarController.tabOrder = [.home, .lib, .sangha, .me]` — `.lamp` is
intentionally excluded (it's an action).

| Tab (`ILBottomNavBar.Tab`) | Coordinator (via `DIContainer`) | Feature |
|---|---|---|
| `.home` | `makeHomeCoordinator` | [Home](home.md) |
| `.lib` | `makeLibraryCoordinator` | [Library](library.md) |
| `.sangha` | `makeSanghaCoordinator` | Sangha (`InnerLamp/Presentation/Scenes/Sangha/`, no OKF concept) |
| `.me` | `makeProfileCoordinator` | Profile (`InnerLamp/Presentation/Scenes/Profile/`, no OKF concept) |
| `.lamp` (action) | `makeMeditationSetupCoordinator` (full-screen modal) | MeditationSetup (`InnerLamp/Presentation/Scenes/MeditationSetup/`, no OKF concept) |

# Navigation

```
AppCoordinator
  └─ showMain() → ILMainTabCoordinator                    (owned by AppCoordinator)
       ILMainTabBarController (BaseTabBarController)
         ├─ homeNavigation    → HomeCoordinator
         ├─ libraryNavigation → LibraryCoordinator
         ├─ sanghaNavigation  → SanghaCoordinator
         └─ meNavigation      → ProfileCoordinator
       onLampTapped → showMeditationSetup() (full-screen modal)
```

Main has no data flow of its own.

# Pending work

- None functionally. One cleanup item remains: delete `ILTabPlaceholderViewController`
  (unused by any tab) — see the resolved open question in
  `Docs/Specs/Main/requirements.md`.

# Related concepts

- [Home](home.md), [Library](library.md) — two of the four owned tabs.
- [Login](login.md), [Onboarding](onboarding.md), [OTP Verification](otp.md) —
  the flows that reach `showMain()`.
- Sangha and Profile tabs have code but no OKF concepts yet (and no specs under
  `Docs/Specs/`).

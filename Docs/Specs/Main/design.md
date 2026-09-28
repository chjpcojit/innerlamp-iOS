# Design — Main

Version: 1.0
Last updated: 2026-09-27
Status: implemented — 4-tab shell with central lamp action; no network

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Main is the post-auth container. It is **not** a screen in the usual MVVM-C
sense — it owns no Entity, UseCase, ViewModel, or StateModel. It is a
coordinator (`ILMainTabCoordinator`) plus a `BaseTabBarController` subclass
(`ILMainTabBarController`) that owns four per-tab coordinators. It is owned by
`AppCoordinator` (`showMain()`), which reaches it from Login success, guest
preview, OTP verify, and (eventually) Splash.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Presentation / Coordinator | `Presentation/Scenes/Main/ILMainTabCoordinator.swift` | Owns `ILMainTabBarController` and the four tab coordinators. Each tab gets its own `BaseNavigationController` so child pushes stay within a tab. Wires `onLampTapped` → `showMeditationSetup()`. |
| Presentation / ViewController | `Presentation/Scenes/Main/ILMainTabBarController.swift` | `BaseTabBarController` subclass; hides the native `UITabBar`, overlays `ILBottomNavBar` (design UI), syncs `activeTab` on `selectedIndex` change, keeps the bar on top, supports `setBottomNavHidden(_:animated:)`. |
| Presentation / ViewController | `Presentation/Scenes/Main/ILTabPlaceholderViewController.swift` | **Unused** — placeholder for tabs that previously had no real screen (Sangha, Me). Superseded by real coordinators; can be deleted. |

No Domain layer (no Entity/UseCase/Repository), no Data layer, no StateModel.
No network.

## Tab wiring

`ILMainTabBarController.tabOrder = [.home, .lib, .sangha, .me]` — `.lamp` is
intentionally excluded (it's an action, not a tab).

| Tab (`ILBottomNavBar.Tab`) | Coordinator (via `DIContainer`) | Feature spec |
|---|---|---|
| `.home` | `makeHomeCoordinator` | `Docs/Specs/Home/` |
| `.lib` | `makeLibraryCoordinator` | `Docs/Specs/Library/` |
| `.sangha` | `makeSanghaCoordinator` | `Docs/Specs/Sangha/` |
| `.me` | `makeProfileCoordinator` | `Docs/Specs/Profile/` |
| `.lamp` (action) | `makeMeditationSetupCoordinator` (full-screen modal) | `Docs/Specs/MeditationSetup/` |

## Navigation flow

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

## Data flow

Main has no data flow of its own — tab switching is handled by
`UITabBarController` (inheriting `BaseTabBarController`'s crossfade), and the
lamp action delegates to the MeditationSetup coordinator. There is no network
call and no Step-by-step Flow.

## Design reference

The bottom bar is `ILBottomNavBar` (`Presentation/Common/DesignSystem/
Components/ILBottomNavBar.swift`) — the design handoff's bottom navigation
(`IL-BottomNav.dc.html`). The native `UITabBar` is hidden because the design
uses a custom bar; tab switching still routes through `UITabBarController` so
the crossfade transition applies.

# Tasks — Main

Version: 1.0
Last updated: 2026-09-27
Status: complete — 4-tab shell with central lamp action

> See `changelog.md` in this folder for the version history of this spec.

> Note: Main is a container/coordinator feature. No Entity/UseCase/ViewModel/
> StateModel phases apply; there is no network layer.

## Phase 1 — Tab bar shell

- [x] Create `ILMainTabBarController` extending `BaseTabBarController`
      (native `UITabBar` hidden, `ILBottomNavBar` overlay, `activeTab` sync,
      keep-on-top, `setBottomNavHidden(_:animated:)`)
- [x] Define `tabOrder = [.home, .lib, .sangha, .me]` (`.lamp` excluded — it's
      an action)
- [x] Create `ILMainTabCoordinator` (owns tab bar + four tab coordinators, each
      with its own `BaseNavigationController`)
- [x] Wire the central lamp button → `showMeditationSetup()` (full-screen modal)
- [x] Wire `DIContainer.makeMainTabCoordinator` + `AppCoordinator.showMain()`

## Phase 2 — Tab content wiring

- [x] Home tab → `makeHomeCoordinator` (own `BaseNavigationController`)
- [x] Library tab → `makeLibraryCoordinator`
- [x] Sangha tab → `makeSanghaCoordinator` (replaces the placeholder)
- [x] Me tab → `makeProfileCoordinator` (replaces the placeholder)

## Phase 3 — API integration

Not applicable — no network call exists in this feature.

## Phase 4 — Documentation

- [x] Per-tab feature READMEs exist under each feature's scene folder (Home,
      Library, Sangha, Profile).
- [ ] Delete `ILTabPlaceholderViewController` (now unused by any tab) — see the
      resolved open question in `requirements.md`.
- [ ] `Docs/Knowledge/features/…` (OKF concepts) for Main's container role — a
      separate `okf-writer` task; see `Docs/Specs/OKF.md`.

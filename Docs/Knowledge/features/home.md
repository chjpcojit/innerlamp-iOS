---
type: Feature
title: Home
description: Signed-in landing screen — greets the user by name and renders the daily quote, weekly/lunar calendar, photos, temples, statistics, bead counter, bell card, suggested sessions and articles (all mock data), routing taps to eight child features.
resource: InnerLamp/Presentation/Scenes/Home/
tags: [home, mvvm-c]
status: draft
generated: { by: claude-code, at: 2026-09-27T14:54:58+07:00 }
sources:
  - path: Docs/Specs/Home/requirements.md
    kind: spec
  - path: Docs/Specs/Home/design.md
    kind: spec
  - path: InnerLamp/Domain/UseCases/Home/ILHomeUseCase.swift
    kind: code
  - path: InnerLamp/Presentation/Scenes/Home/ILHomeCoordinator.swift
    kind: code
  - path: InnerLamp/Domain/Entities/ILHomeEntity.swift
    kind: code
---

# Summary

Home is the first tab of the post-auth `ILMainTabBarController` and a hub screen:
it greets the signed-in user by their registered display name (falling back to a
guest label), shows the current solar + lunar date, and renders the sections in
order — weekly strip, lunar hero card (daily quote), photo gallery, temple
carousel, statistics, bead counter, bell card, suggested sessions, articles.
Taps route to eight child features (Mala, LunarCalendar, Photos, Bell, Events,
Article, Temple, MeditationSetup).

All content is **mock data** in `ILHomeUseCaseImpl` (each block carries a
`// TODO: networkService` comment); the only real computations are the lunar
date (`ILLunarCalendar.solarToLunar`) and the greeting name (read from
`KeychainService` under a temporary key).

**Current limitation**: there is no dashboard/content API — see
[Pending work](#pending-work).

# Architecture

MVVM-C + Clean Architecture. Home is the first tab, so `ILHomeCoordinator` is
owned by `ILMainTabCoordinator` (which gives it its own
`BaseNavigationController`), not by `AppCoordinator`.

| Layer | Type | File |
|---|---|---|
| Domain / Entity | Domain Entity | `Domain/Entities/ILHomeEntity.swift` — `displayName`, `weekPages`, `selectedDayID`, `lunarDate`, `eventMonths`, session/streak/mala stats, `suggestedSessions`, `photos`, `temples`, `articles`; plus the value enums/structs (`ILHomeSessionKind`/`Tone`/`Glyph`, `ILHomeEventTone`, `ILHomeQuoteEntity`, `ILHomeWeekDayEntity`, `ILHomeWeekPageEntity`, `ILHomeLunarDateEntity`, `ILHomeEventItemEntity`, `ILHomeEventMonthEntity`, `ILHomePhotoEntity`, `ILHomeTempleEntity`, `ILHomeArticleEntity`, `ILHomeSuggestedSessionEntity`) |
| Domain / UseCase | UseCase | `Domain/UseCases/Home/ILHomeUseCase.swift` — `getInitialState()` (mock + Keychain name + lunar/week/event computation), `incrementBead(_:)` (wraps to 1 after 108), `resetBeads(_:)`, `selectDay(_:in:)`; no Repository |
| Presentation / State | State Model | `Presentation/Scenes/Home/ILHomeStateModel.swift` — UI-only, pre-formatted display strings, no UIKit import |
| Presentation / ViewModel | ViewModel | `Presentation/Scenes/Home/ILHomeViewModel.swift` — `Input -> Output`; owns `ILHomeNavEvent` (8 cases); `applyEntity(_:)` maps Entity → StateModel |
| Presentation / Coordinator | Coordinator | `Presentation/Scenes/Home/ILHomeCoordinator.swift` — `setViewControllers([ILHomeViewController])`; spawns child coordinators for the 8 destinations |
| Presentation / ViewController | ViewController | `Presentation/Scenes/Home/ILHomeViewController.swift` |
| Feature-scoped views | View | `Presentation/Scenes/Home/Views/ILHomeGreetingHeaderView.swift`, `ILHomeWeekCalendarView.swift`, `ILHomeLunarHeroCardView.swift`, `ILHomeEventsCarouselView.swift`, `ILHomePhotoGridView.swift`, `ILHomeTempleCarouselView.swift`, `ILHomeBellCardView.swift`, `ILHomeArticleListView.swift` |
| Tests | Unit tests | `InnerLampTests/ILHomeViewModelTests.swift` (13 tests) |

# Navigation

```
ILMainTabCoordinator (tab "Trang chủ")
  └─ ILHomeCoordinator                        (owned by Main, not AppCoordinator)
       setViewControllers([ILHomeViewController])   ← root of the Home tab's nav
       .openMala            → showMala()            (push ILMalaCoordinator)
       .openLunarCalendar   → showLunarCalendar()
       .openPhotos          → showPhotos()
       .openBell            → showBell()
       .openEvents          → showEvents()
       .openArticle(id)     → showArticle(id)
       .openTemple(id)      → showTemple(id)
       .openMeditationSetup → showMeditationSetup() (full-screen modal)
```

Bead taps are synchronous (`incrementBead` / `resetBeads` mutate the entity and
re-emit state) — no persistence, no network. The "sutra" / "offering"
suggested-session rows deliberately do nothing (those destinations are not
built).

# Pending work

- A real dashboard/content API. All content (daily quote, statistics, suggested
  sessions, photos, temples, articles, events) is mock data in
  `ILHomeUseCaseImpl` with TODO comments.
  > ⚠️ Not confirmed: the dashboard/content API contract(s) — no home-dashboard
  > endpoint in `Docs/Specs/API/openapi.yaml` v3.9. Blocks `tasks.md` Phase 3.
- A real session/current-user service. The greeting name has no source yet
  (empty → "khách", TD-Home-002); the old `signup_pending_credentials` read was removed.
- The bead count is memory-only — not persisted and not synced with the
  full-screen Mala screen.
- Promote to `stable` once the dashboard API lands and the flow is exercised
  end-to-end.

# Known gaps vs. design

- The shipped section order (photos → temples → statistics → beads → bell →
  suggested sessions → articles) differs from the acceptance-criteria order; the
  spec records both and flags the divergence.

# Related concepts

- [Main](main.md) (`InnerLamp/Presentation/Scenes/Main/`) — owns this tab via
  `ILMainTabCoordinator`.
- [Bell](bell.md) (`InnerLamp/Presentation/Scenes/Bell/`) — reached via the bell
  card (`openBell`).
- [Temple](temple.md) (`InnerLamp/Presentation/Scenes/Temple/`) — reached via the
  temple carousel (`openTemple(id)`); the two share the `home.temple.*`
  localization keys for the 8-temple catalog.
- [Library](library.md) (`InnerLamp/Presentation/Scenes/Library/`) — sibling tab.

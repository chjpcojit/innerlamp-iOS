# Design — Home

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full UI + local logic with mock data; no dashboard API

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Home follows MVVM-C + Clean Architecture per `AGENTS.md`. It is the first tab
of `ILMainTabBarController`, so `ILHomeCoordinator` is owned by
`ILMainTabCoordinator` (which gives it its own `BaseNavigationController`), not
by `AppCoordinator` directly. It is a hub screen: it renders mock content and
routes taps to eight child features. There is **no network** — the UseCase
returns mock data and reads the greeting name from `KeychainService`.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILHomeEntity.swift` | Pure business fields: `displayName`, `weekPages` (5 weeks), `selectedDayID`, `lunarDate`, `eventMonths`, `sessionMinutesDone/Goal`, `streakDays`, `streakWeekProgress`, `malaCount/Goal`, `malaMantraText`, `suggestedSessions`, `photos`, `temples`, `articles`. Plus the value enums/structs (`ILHomeSessionKind/Tone/Glyph`, `ILHomeEventTone`, `ILHomeQuoteEntity`, `ILHomeWeekDayEntity` (with `lunarMonth`/`isHoangDao`), `ILHomeWeekPageEntity`, `ILHomeLunarDateEntity`, `ILHomeEventItemEntity`, `ILHomeEventMonthEntity`, `ILHomePhotoEntity`, `ILHomeTempleEntity`, `ILHomeArticleEntity`, `ILHomeSuggestedSessionEntity`). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Home/ILHomeUseCase.swift` | `getInitialState()` (mock data + `KeychainService` name read + lunar/week/event computation), `incrementBead(_:)` (wraps to 1 after goal), `resetBeads(_:)`, `selectDay(_:in:)` (recompute lunar hero for tapped day). No Repository; content is mock. |
| Presentation / State | `Presentation/Scenes/Home/ILHomeStateModel.swift` | UI-only state: greeting/avatar/date text, week strip (`weekdayLabels`/`weekPages`/`weekLegend` with `ILHomeWeekDotKind`), lunar hero, event months, session progress, streak, mala progress, suggested sessions, photos, temples, articles — all as presentation models with pre-formatted strings. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Home/ILHomeViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILHomeNavEvent` (8 cases) and `navigationEventPublisher`; maps `ILHomeEntity` → `ILHomeStateModel` via `applyEntity(_:)`. |
| Presentation / Coordinator | `Presentation/Scenes/Home/ILHomeCoordinator.swift` | `setViewControllers([ILHomeViewController])`; subscribes `navigationEventPublisher`, spawns child coordinators for the 8 destinations. |
| Presentation / ViewController | `Presentation/Scenes/Home/ILHomeViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/Home/Views/ILHomeGreetingHeaderView.swift`, `ILHomeWeekCalendarView.swift`, `ILHomeLunarHeroCardView.swift`, `ILHomeEventsCarouselView.swift`, `ILHomePhotoGridView.swift`, `ILHomeTempleCarouselView.swift`, `ILHomeBellCardView.swift`, `ILHomeArticleListView.swift` | One view per Home section. |

## Navigation flow

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

## Data flow (screen load)

1. `ILHomeViewModel.handleViewDidLoad()` → `useCase.getInitialState()`.
2. `ILHomeUseCaseImpl.getInitialState()` builds an `ILHomeEntity` from mock data
   (daily quote, statistics, sessions, photos, temples, articles, events) plus a
   `KeychainService` read of the display name and real lunar-calendar
   conversion via `ILLunarCalendar`.
3. `ILHomeViewModel.applyEntity(_:)` maps Entity → `ILHomeStateModel`
   (applying the guest-name fallback, greeting format, weekday labels, progress
   ratios, and pre-formatted strings).
4. `ILHomeViewController` renders each section from the state model.

Bead taps are synchronous: `incrementBead` / `resetBeads` mutate the entity and
re-emit state — no persistence, no network.

## Deliberately stubbed / mock for now

`ILHomeUseCaseImpl.getInitialState()` returns **mock content** for: the daily
quote (`home.lunar.verse.*`), session/streak statistics (hardcoded `12/20`,
`42`, a fixed `[0.3, 0.5, …]` progress array), suggested sessions (3 fixed
items), photos (`pg-1…pg-12`), temples (8 fixed temples), articles (5 fixed
articles), and events (2 months of sample events). Each block carries a
`// TODO: … networkService` comment. The greeting name is read via
`KeychainService` key `signup_pending_credentials` — a temporary arrangement
until a real session service exists. Completing this is `tasks.md` Phase 3.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
block `isHome`. Section order in the shipped UI: photos → temples → statistics
→ beads → bell → suggested sessions → articles (after the header + week strip +
lunar hero). See `InnerLamp/Presentation/Scenes/Home/README.md` for the full
design-vs-implementation comparison and changelog.

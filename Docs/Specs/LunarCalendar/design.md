# Design — LunarCalendar

Version: 1.0
Last updated: 2026-09-27
Status: implemented — 6-month lunar calendar carousel with pure local computation

> See `changelog.md` in this folder for the version history of this spec.

## Overview

LunarCalendar ("Lịch âm") follows MVVM-C + Clean Architecture per `AGENTS.md`.
It is a **leaf screen** — `ILLunarCalendarCoordinator` has no delegate. It is
created by `ILHomeCoordinator` (the "Lịch âm" link / lunar hero card on Home →
`ILHomeNavEvent.openLunarCalendar`) and pushed onto the Home tab's
`BaseNavigationController`. There is **no network** — all data is computed
locally from the shared `ILLunarCalendar` utility.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILLunarCalendarEntity.swift` | `ILLunarCalendarDayCategory` (newMoon / fullMoon / fastDay / ordinary), `ILLunarCalendarDayEntity`, `ILLunarCalendarMonthEntity`, `ILLunarCalendarEntity` (months, todayID, selectedDayID, `selectedDay`, `day(withID:)`). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/LunarCalendar/ILLunarCalendarUseCase.swift` | `getInitialState()` (6 months via `ILLunarCalendar`), `selectDay(id:in:)`, `upcomingSpecialDays(in:limit:)`. Pure computation, no network/disk. |
| Presentation / State | `Presentation/Scenes/LunarCalendar/ILLunarCalendarStateModel.swift` | UI-only state: day/month models (formatted solar/lunar text, today/selected/fast flags), header title/subtitle, current page, day-card copy, upcoming rows. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/LunarCalendar/ILLunarCalendarViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILLunarCalendarNavEvent` (`.close`); page clamping, day selection, Entity→StateModel mapping + date/copy formatting. |
| Presentation / Coordinator | `Presentation/Scenes/LunarCalendar/ILLunarCalendarCoordinator.swift` | Leaf — `pushViewController`; `.close` → pop + `finish()`. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/LunarCalendar/ILLunarCalendarViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/LunarCalendar/Views/ILLunarCalendarPagerBarView.swift`, `ILLunarCalendarMonthCarouselView.swift`, `ILLunarCalendarMonthCardView.swift`, `ILLunarCalendarDayInfoCardView.swift` | Pager bar, month carousel, month card, and day-info card. |
| Shared component | `DesignSystem/Components/ILChevronCircleButton.swift` | Round ‹ › button, extracted as content-free/shared. |
| Core utility | `Core/Utils/ILLunarCalendar.swift` | Lunar conversion (`solarToLunar`, `lunarMonthLabel`, `canChiYear`). Shared with Home. |

## Navigation flow

```
ILHomeCoordinator (Home tab)
  └─ showLunarCalendar() → ILLunarCalendarCoordinator   (leaf, no delegate)
       push ILLunarCalendarViewController
       (.close) → pop + finish()
```

## Data flow

1. `ILLunarCalendarViewModel` loads `useCase.getInitialState()` (6 months
   computed from `ILLunarCalendar`) and maps to `ILLunarCalendarStateModel`
   (formatted cell text, day-card copy per category, upcoming fast days).
2. `setPage` clamps the page to `0...months.count-1` and re-emits state
   (updating the header).
3. `handleDayTapped(id)` → `selectDay` updates `selectedDayID` and re-emits.

There is no network call and no Step-by-step Flow.

## Deliberately provisional

The day-card title/body are provisional per-category strings
(`lunarCalendar.hero.*`); the "upcoming" rows are fast days only. See the ⚠️
items in `requirements.md` Pending.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
screen `cal`. See `InnerLamp/Presentation/Scenes/LunarCalendar/README.md` for
the full design-vs-implementation comparison and changelog.

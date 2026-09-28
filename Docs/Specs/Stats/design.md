# Design — Stats

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — UI + local logic done; real data integration pending

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Stats follows MVVM-C + Clean Architecture per `AGENTS.md` and
`Core/Base/README.md`, matching the canonical single-screen feature shape.
It is **scoped to one section**: a child screen of the Me tab, pushed by
`ILProfileCoordinator` (not `AppCoordinator`) when the Profile heatmap card
is tapped. There is **no network call yet** — `getStats()` returns local
sample data — so no Step-by-step Flow section is needed and the data layer
is deliberately stubbed (see below).

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILStatsEntity.swift` | Pure business fields only: `streakDays`, `nextMilestone`, `totalHours`, `hoursDeltaVsLastMonth`, `usualStartHour`/`usualStartMinute`, `morningSharePercent`, `weeklyMinutes`, `averageMinutesPerDay`, `practiceMix`, `reminder`. Also the value types `ILStatsPracticeKind`, `ILStatsMilestoneEntity`, `ILStatsWeekEntity`, `ILStatsPracticeShareEntity`, `ILStatsReminderEntity`. No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Stats/ILStatsUseCase.swift` | `getStats() -> ILStatsEntity`. Currently returns hardcoded sample data (a TODO) — to be replaced by an `ILStatsRepository` once a contract exists. |
| Presentation / State | `Presentation/Scenes/Stats/ILStatsStateModel.swift` | UI-only state: `ILStatsStreakModel`, `ILStatsTileModel` + `ILStatsFootnoteTone`, `ILStatsWeeklyChartModel` + `ILStatsBarModel`, `ILStatsMixItemModel`, `ILStatsStateModel`. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Stats/ILStatsViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILStatsNavEvent` publisher; Entity → StateModel mapping + formatting helpers. |
| Presentation / Coordinator | `Presentation/Scenes/Stats/ILStatsCoordinator.swift` | Pushes `ILStatsViewController`; handles `.goBack` (pop + finish); `.openReminder` is a TODO (no destination yet). No delegate — every outgoing navigation is either a pop or has no destination yet. |
| Presentation / ViewController | `Presentation/Scenes/Stats/ILStatsViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`; sticky `ILNavBar` band + scroll content; hides/restores bottom nav. |
| Feature-scoped view | `Presentation/Scenes/Stats/Views/ILStatsReminderCardView.swift` | Gold-bordered CTA card with a bell icon tile, title + reminder summary, and a trailing chevron; the whole card is one tap target. |
| Shared Design System components | `ILStatHeroCardView`, `ILStatTileView`, `ILStatBarChartCardView`, `ILStatBreakdownCardView` (under `Presentation/Common/DesignSystem/Components/`) | Generic stat cards reused by this screen. |

## Navigation flow

```
ILProfileCoordinator (Me tab)
  └─ ILProfileNavEvent.openStats → showStats()
       ILStatsCoordinator
         push ILStatsViewController
         (back chip) → .goBack → popViewController + finish()
         (reminder card) → .openReminder → (TODO — `remind` screen not built)
```

## Data flow

1. `ILStatsViewController` sends `viewDidLoad` after subscribing to
   `Output.state` (a `PassthroughSubject` does not replay a value sent
   before a subscriber exists).
2. `ILStatsViewModel` calls `useCase.getStats()` (currently sample data),
   maps the `ILStatsEntity` into an `ILStatsStateModel` — streak milestone
   remaining/progress, tile values + footnote tone, bar normalization
   (height ratio + opacity against the peak week), delta/time/reminder
   formatting — and emits `.success(state)`.
3. The ViewController renders the state: streak card, tiles, chart, mix,
   and reminder subtitle. `.idle`/`.loading` do nothing; `.failure` is a
   TODO (no real source can fail yet).

## Deliberately stubbed for now

- `ILStatsUseCaseImpl.getStats()` returns hardcoded sample data (42-day
  streak, 48-day milestone, 168 total hours, etc.) because there is no
  confirmed stats API / local store yet. The handoff README suggests stats
  should be written **local-first, then synced**, but the exact contract is
  unconfirmed:

  > ⚠️ Not confirmed: the exact stats data contract (backend API vs
  > local-first store, and the field shapes each provides) — blocks
  > `tasks.md` Phase 3 (creating `ILStatsDTO`/`Mapper`/`ILStatsRepository`
  > and replacing the stub).

- `ILStatsCoordinator` ignores `.openReminder` (TODO) because the
  mindfulness bell reminder (`remind`) screen does not exist yet.

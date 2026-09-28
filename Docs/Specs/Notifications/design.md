# Design — Notifications

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full UI with mock data; "Ngồi ngay" destination not wired

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Notifications ("Thông báo") follows MVVM-C + Clean Architecture per `AGENTS.md`.
It is a **pushed screen** inside the "Tôi" tab, owned by `ILProfileCoordinator`
(reached via the Profile menu's "Thông báo" row). It has no delegate —
`.goBack` pops, and `.openSetup` is a TODO. There is **no network** — the
UseCase returns static mock data.

> Note on naming: the scene is "Notifications" (plural), but the Domain entity
> is a single `ILNotificationEntity` (+ `ILNotificationUpcomingEntity`), like
> `ILLibraryEntity` aggregates `ILLibraryItemEntity`.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILNotificationEntity.swift` | `ILNotificationKind` (bell / sangha / community / offering), `ILNotificationEntity` (id, kind, title, body, timestamp, isRead), `ILNotificationUpcomingEntity` (eyebrow, title). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Notifications/ILNotificationsUseCase.swift` | `getUpcoming()` / `getNotifications()` — static mocks (TODO: repository → network/push). |
| Presentation / State | `Presentation/Scenes/Notifications/ILNotificationsStateModel.swift` | UI-only state: `ILNotificationItemModel` (relative time formatted), `ILNotificationsHeroModel`, `hero` (nil when dismissed) + `items`. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Notifications/ILNotificationsViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILNotificationsNavEvent` (`.goBack`, `.openSetup`); Entity→StateModel mapping + relative-time formatting; `skipTonight` dismisses the hero. |
| Presentation / Coordinator | `Presentation/Scenes/Notifications/ILNotificationsCoordinator.swift` | `pushViewController`; `.goBack` → pop + finish; `.openSetup` → TODO. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/Notifications/ILNotificationsViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/Notifications/Views/ILNotificationsHeroCardView.swift`, `ILNotificationRowView.swift` | Hero card and notification row. |

## Navigation flow

```
ILProfileCoordinator (tab "Tôi")
  └─ openNotifications → ILNotificationsCoordinator   (no delegate)
       push ILNotificationsViewController
       (.goBack) → pop + finish()
       (.openSetup) → TODO (→ showMeditationSetup once wired)
```

## Data flow

1. `ILNotificationsViewModel` loads `useCase.getUpcoming()` /
   `useCase.getNotifications()` (mock) and maps to `ILNotificationsStateModel`
   (relative time formatting).
2. `handleSkipTonight()` sets `hero = nil` and re-emits.
3. `sitNowTapped` → `.openSetup`; `closeTapped` → `.goBack`.

There is no network call and no Step-by-step Flow.

## Deliberately mock / stub

`ILNotificationsUseCaseImpl` returns hardcoded upcoming + 4 notifications with
`// TODO` comments. `isRead` is static (no mark-as-read). Completing this is
`tasks.md` Phase 3, blocked on the notifications/push API contract.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
prototype screen `notif`. See `InnerLamp/Presentation/Scenes/Notifications/
README.md` for the full design-vs-implementation comparison and changelog.

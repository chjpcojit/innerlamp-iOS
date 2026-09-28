# Design — Events

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — UI + tab logic done with mock data; Register not built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Events ("Sự kiện & khóa học") follows MVVM-C + Clean Architecture per
`AGENTS.md`. It is a **leaf screen** — `ILEventsCoordinator` has no delegate.
It is pushed from two parents: the Sangha tab's "Sự kiện & khóa học" chip
(`ILSanghaCoordinator.openEvents`) and Home's events "Tất cả" button
(`ILHomeCoordinator.showEvents()`). There is **no network** — the UseCase
returns static mock data.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILEventsEntity.swift` | Pure business fields: `ILEventsEntity` (featured + upcoming/courses/registered arrays), `ILEventsFeaturedEntity`, `ILEventsEventEntity`, and the enums `ILEventsTone` / `ILEventsStatus` (open / closing / upcoming / registered). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Events/ILEventsUseCase.swift` | `getEvents()` — returns static mock data (TODO: repository → network). No Repository. |
| Presentation / State | `Presentation/Scenes/Events/ILEventsStateModel.swift` | UI-only state: `ILEventsTab`, `ILEventsFeaturedModel`, `ILEventsListItemModel`, and `ILEventsStateModel` with pre-formatted status/section labels. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Events/ILEventsViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILEventsNavEvent` (`.goBack`, `.openRegister(eventId:)`); Entity→StateModel mapping + status/tab-section label formatting. |
| Presentation / Coordinator | `Presentation/Scenes/Events/ILEventsCoordinator.swift` | Leaf — `pushViewController`; `.goBack` → pop + `finish()`; `.openRegister` is a TODO. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/Events/ILEventsViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/Events/Views/ILEventsHeroCardView.swift`, `ILEventsListItemView.swift` | Hero card and list-row views. |

## Navigation flow

```
ILSanghaCoordinator (Sangha tab)            ILHomeCoordinator (Home tab)
  └─ openEvents → ILEventsCoordinator         └─ showEvents() → ILEventsCoordinator
       push ILEventsViewController                 (leaf, no delegate)
       (.goBack) → pop + finish()
       (.openRegister(id)) → TODO (Register screen not built)
```

## Data flow

1. `ILEventsViewModel` loads `useCase.getEvents()` (mock) and maps it to
   `ILEventsStateModel` for the selected tab.
2. `handleTabSelected(tab)` re-maps the same entity for the new tab (no re-fetch
   — data is static).
3. `handleRegisterTapped(id:)` emits `.openRegister(eventId: id)`.

There is no network call and no Step-by-step Flow.

## Deliberately stubbed / mock for now

`ILEventsUseCaseImpl.getEvents()` returns a hardcoded `ILEventsEntity` (1
featured event, 4 upcoming, 3 courses, 2 registered) with a
`// TODO: … networkService` comment. Completing this is `tasks.md` Phase 3,
blocked on the events API contract. The Register destination (`.openRegister`)
is also unimplemented.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
prototype screen `events`. See `InnerLamp/Presentation/Scenes/Events/README.md`
for the full design-vs-implementation comparison and changelog.

# Design — Sangha

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full tab UI with mock data; destinations partially built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Sangha ("Đạo tràng") follows MVVM-C + Clean Architecture per `AGENTS.md`. It is
**tab 3** of `ILMainTabBarController`, so `ILSanghaCoordinator` is owned by
`ILMainTabCoordinator` (which gives it its own `BaseNavigationController`).
There is **no network** — the UseCase returns static mock data.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILSanghaEntity.swift` | `ILSanghaLiveSessionEntity`, `ILSanghaCommunityEntity`, `ILSanghaPostEntity`, and `ILSanghaEntity` (live session, community, posts). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Sangha/ILSanghaUseCase.swift` | `getSangha()` — returns static mock (TODO: repository → network). |
| Presentation / State | `Presentation/Scenes/Sangha/ILSanghaStateModel.swift` | UI-only state: live session model, community model, post models (formatted counts / caption / meta / engagement). No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Sangha/ILSanghaViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILSanghaNavEvent` (6 cases); Entity→StateModel mapping + count / relative-time / initial helpers. |
| Presentation / Coordinator | `Presentation/Scenes/Sangha/ILSanghaCoordinator.swift` | `setViewControllers([ILSanghaViewController])`; `.openEvents`/`.openCommunity`/`.openPost` wired; `.openFindSangha`/`.startSitting`/`.openCompose` TODO. |
| Presentation / ViewController | `Presentation/Scenes/Sangha/ILSanghaViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/Sangha/Views/ILSanghaLiveSessionCardView.swift`, `ILSanghaCommunityCardView.swift`, `ILSanghaPostCardView.swift`, `ILSanghaPostListView.swift` | The four section views. |

## Navigation flow

```
ILMainTabCoordinator (tab "Đạo tràng")
  └─ ILSanghaCoordinator                          (owned by Main, not AppCoordinator)
       setViewControllers([ILSanghaViewController])   ← root of the Sangha tab's nav
       .openEvents     → showEvents()   (ILEventsCoordinator)
       .openCommunity  → showTemple(id) (ILTempleCoordinator)
       .openPost(id)   → showPost(id)   (ILPostCoordinator)
       .openFindSangha / .startSitting / .openCompose → TODO
```

## Data flow

1. `ILSanghaViewModel` loads `useCase.getSangha()` (mock) and maps it to
   `ILSanghaStateModel` (formatted counts, relative time, author initial).
2. Nav taps emit `.openEvents` / `.openCommunity(id)` / `.openPost(id)` (or the
   three TODO events).

There is no network call and no Step-by-step Flow.

## Deliberately mock / stub

`ILSanghaUseCaseImpl.getSangha()` returns hardcoded data (312 live participants,
one community "sangha.tuquang", one post "post-2") with a `// TODO` comment.
The live count is a static snapshot (no realtime). Completing this is
`tasks.md` Phase 3, blocked on the community API contract.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
prototype screen `sangha`. See `InnerLamp/Presentation/Scenes/Sangha/README.md`
for the full design-vs-implementation comparison and changelog.

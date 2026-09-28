# Design — Awards

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; awards source unconfirmed

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Awards follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a **section
screen** owned by the Profile coordinator, reached from the Profile "Dấu ấn tu
tập" preview. The badge definitions and earned/progress state have an unconfirmed
source (local computation vs backend).

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILAwardsEntity.swift` | Pure business fields: badge id, title, subtitle, state (earned / newlyEarned / locked(progress)). |
| Domain / UseCase | `Domain/UseCases/Awards/ILAwardsUseCase.swift` | `loadAwards()` (delegates to repository), progress formatting. |
| Domain / Repository | `Domain/Repositories/ILAwardsRepository.swift` | `listAwards() async throws -> [ILAwardsEntity]` — abstracts local/remote source. |
| Data / Repository | `Data/Repositories/ILAwardsRepositoryImpl.swift` | Local store (Core Data) and/or `NetworkService`. (Not yet created.) |
| Presentation / State | `Presentation/Scenes/Awards/ILAwardsStateModel.swift` | UI-only state: progress count, recent badge, grid items. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Awards/ILAwardsViewModel.swift` | `Input -> Output`; owns `ILAwardsNavEvent` (openStats, back). |
| Presentation / Coordinator | `Presentation/Scenes/Awards/ILAwardsCoordinator.swift` | Pushes `ILAwardsViewController`; forwards `openStats`. |
| Presentation / ViewController | `Presentation/Scenes/Awards/ILAwardsViewController.swift` | Recent-badge card, 3-column grid, fixed bottom button. |

## Navigation flow

```
ProfileCoordinator
  └─ (tap "Dấu ấn tu tập") → showAwards() → ILAwardsCoordinator
       push ILAwardsViewController
       (tap "Xem tiến trình tu tập") → openStats → Stats
       (tap back) → pop
```

## Data flow

Single load, no multi-call sequence → Step-by-step Flow not required:

1. `viewDidLoad` → `ILAwardsViewModel.load()` → `ILAwardsRepository.listAwards()`
   → render recent badge + grid.

## Deliberately stubbed for now

`ILAwardsUseCase.loadAwards()` is a one-line stub (`print("TODO: …")`) until the
badge/progress source is confirmed — see `requirements.md` Pending. No
`ILAwardsRepositoryImpl` exists yet (`tasks.md` Phase 3).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
screen `awards`, and `Mo-ta-tinh-nang.md` §5 "Thành tựu (Dấu ấn tu tập)".

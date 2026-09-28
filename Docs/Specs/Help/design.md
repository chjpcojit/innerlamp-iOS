# Design — Help

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; FAQ content source unconfirmed

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Help follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a **section
screen** owned by the Settings coordinator, reached via
`ILSettingsNavEvent.openHelp` (already referenced in Settings code). The only
open question is the FAQ content source (static vs fetched), which decides
whether a Domain/Repository layer is needed at all — modeled here as a thin
UseCase with an unconfirmed backing.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILHelpEntity.swift` | Pure business fields: question id, title, body. |
| Domain / UseCase | `Domain/UseCases/Help/ILHelpUseCase.swift` | `loadFAQ()` (delegates to repository, or reads bundled data once the source is confirmed). |
| Domain / Repository | `Domain/Repositories/ILHelpRepository.swift` | `listFAQ() async throws -> [ILHelpEntity]` — only needed if fetched. (Conditional, unconfirmed.) |
| Data / Repository | `Data/Repositories/ILHelpRepositoryImpl.swift` | `NetworkService` or bundled loader; DTO ↔ Entity. (Not yet created — conditional.) |
| Presentation / State | `Presentation/Scenes/Help/ILHelpStateModel.swift` | UI-only state: FAQ items + expanded index, search text. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Help/ILHelpViewModel.swift` | `Input -> Output`; owns `ILHelpNavEvent` (openSearch, back). |
| Presentation / Coordinator | `Presentation/Scenes/Help/ILHelpCoordinator.swift` | Pushes `ILHelpViewController`. |
| Presentation / ViewController | `Presentation/Scenes/Help/ILHelpViewController.swift` | Intro, search field, accordion FAQ, footer. |

## Navigation flow

```
SettingsCoordinator
  └─ (tap "Trợ giúp") → openHelp → ILHelpCoordinator
       push ILHelpViewController
       (tap search) → openSearch → Search
       (tap back) → pop
```

## Data flow

Single load (no multi-call sequence → Step-by-step Flow not required):

1. `viewDidLoad` → `ILHelpViewModel.load()` → `ILHelpUseCase.loadFAQ()` →
   render accordion.
2. Search submit navigates to the Search feature (no local query).

## Deliberately stubbed for now

`ILHelpUseCase.loadFAQ()` is a one-line stub (`print("TODO: …")`) until the FAQ
content source is confirmed — see `requirements.md` Pending. If the source turns
out to be static bundled content, the Domain/Repository layer is dropped
entirely (`tasks.md` Phase 3 records this decision).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
screen `faq`, and `Mo-ta-tinh-nang.md` §7 "Trợ giúp".

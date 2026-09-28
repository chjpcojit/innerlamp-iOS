# Design — SessionComplete

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; session-record source unconfirmed

> See `changelog.md` in this folder for the version history of this spec.

## Overview

SessionComplete follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a
**section screen** owned by the MeditationSession coordinator, reached when a
session ends. Its main action (save to journal) is local-first per the design's
"local-first" note, so the only open question is whether the session record is
also sent to a backend.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILSessionCompleteEntity.swift` | Pure business fields: session duration, completed mood (enum), dedication target, streak, total hours, people-count. |
| Domain / UseCase | `Domain/UseCases/SessionComplete/ILSessionCompleteUseCase.swift` | `saveSession(...)` (delegates to repository/local store), mood selection rules. |
| Domain / Repository | `Domain/Repositories/ILSessionCompleteRepository.swift` | `recordSession(_:) async throws -> Void` — abstracts local vs remote persistence (unconfirmed). |
| Data / Repository | `Data/Repositories/ILSessionCompleteRepositoryImpl.swift` | Local store (Core Data) and/or `NetworkService`; DTO ↔ Entity. (Not yet created.) |
| Presentation / State | `Presentation/Scenes/SessionComplete/ILSessionCompleteStateModel.swift` | UI-only state: stats, mood options + selected, dedication text, saving flag. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/SessionComplete/ILSessionCompleteViewModel.swift` | `Input -> Output`; owns `ILSessionCompleteNavEvent` (saveToJournal, skip). |
| Presentation / Coordinator | `Presentation/Scenes/SessionComplete/ILSessionCompleteCoordinator.swift` | Presents `ILSessionCompleteViewController`; forwards save/skip to the MeditationSession coordinator. |
| Presentation / ViewController | `Presentation/Scenes/SessionComplete/ILSessionCompleteViewController.swift` | Completion title, stats, mood chips, dedication, bottom actions. |

## Navigation flow

```
MeditationSessionCoordinator
  └─ (session ends / "Kết thúc sớm") → showSessionComplete(...) → ILSessionCompleteCoordinator
       present ILSessionCompleteViewController
       (tap "Ghi vào nhật ký") → openJournalWrite → Journal (write)
       (tap "Để sau") → backToHome → Home
```

## Data flow

Single save action, no multi-call sequence → Step-by-step Flow not required:

1. `saveSession` → `ILSessionCompleteUseCase.saveSession(...)` →
   `ILSessionCompleteRepository.recordSession(_:)` (local-first) → navigate to
   Journal write.
2. "Để sau" → skip, return Home, no persistence.

## Deliberately stubbed for now

`ILSessionCompleteUseCase.saveSession(...)` is a one-line stub
(`print("TODO: …")`) until the persistence model (local vs remote) is confirmed
— see `requirements.md` Pending. No `ILSessionCompleteRepositoryImpl` exists yet
(`tasks.md` Phase 3).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
screen `done`, and `Mo-ta-tinh-nang.md` §4 "Hoàn thành".

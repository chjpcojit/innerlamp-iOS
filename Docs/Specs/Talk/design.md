# Design — Talk

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; talk API unconfirmed

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Talk follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a **section
screen** owned by the Library coordinator, reached from the Library featured
Dharma-talk card. It presents a talk detail with inline playback and chapter
seek, and hands off to MeditationSetup from its follow-up card.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILTalkEntity.swift` | Pure business fields: id, kicker, title, speaker, durationSeconds, playCount, chapters (`[ILTalkChapterEntity]` — startTime, title), audioURL. |
| Domain / UseCase | `Domain/UseCases/Talk/ILTalkUseCase.swift` | `getTalk(id:)` — delegates to repository; `ILTalkError` maps failures. |
| Domain / Repository | `Domain/Repositories/ILTalkRepository.swift` | `getTalk(id:) async throws -> ILTalkEntity`. Entity in/out. |
| Data / Repository | `Data/Repositories/ILTalkRepositoryImpl.swift` | Wraps `NetworkService`; DTO ↔ Entity, `NetworkError` → `ILTalkError`. (Not yet created.) |
| Data / DTO + Mapper | `Data/DTOs/ILTalkDTO.swift` + `Data/DTOs/Mappers/ILTalkMapper.swift` | Wire shape for the talk detail response; Entity ↔ DTO. (Not yet created.) |
| Presentation / State | `Presentation/Scenes/Talk/ILTalkStateModel.swift` | UI-only state: loading/error, playback state (isPlaying, current/remaining time), formatted chapters. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Talk/ILTalkViewModel.swift` | `Input -> Output`; owns `ILTalkNavEvent` (openMeditationSetup, back). |
| Presentation / Coordinator | `Presentation/Scenes/Talk/ILTalkCoordinator.swift` | Pushes `ILTalkViewController`; forwards navigation to the Library coordinator. |
| Presentation / ViewController | `Presentation/Scenes/Talk/ILTalkViewController.swift` | Transparent hero header, player controls, chapter list, follow-up card. |

## Navigation flow

```
LibraryCoordinator
  └─ (tap featured Dharma-talk card) → showTalk(id:) → ILTalkCoordinator
       push ILTalkViewController
       (tap follow-up card) → openMeditationSetup → MeditationSetup
       (tap back) → pop
```

## Data flow

Single fetch + local playback (no multi-call sequence → Step-by-step Flow not
required):

1. `viewDidLoad` → `ILTalkViewModel.load()` → `ILTalkRepository.getTalk(id:)` →
   render hero, chapters, and start playback of `audioURL`.
2. Playback (play/pause/seek/chapter-tap) is local `AVFoundation` control, no
   additional network calls.

## Deliberately stubbed for now

`ILTalkUseCase.getTalk(id:)` is a one-line stub (`print("TODO: …")`) until the
talk API contract lands — see `requirements.md` Pending. No DTO / Mapper /
Endpoint / `ILTalkRepositoryImpl` exist yet (`tasks.md` Phase 3). The audio
playback itself is a separate open item (stream URL vs download).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
screen `talk`, and `Mo-ta-tinh-nang.md` §3 "Pháp thoại".

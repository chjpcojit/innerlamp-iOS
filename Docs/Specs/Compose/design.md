# Design — Compose

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; publish API unconfirmed

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Compose follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a **modal
sheet** owned by the Sangha coordinator, reached via the existing
`ILSanghaNavEvent.openCompose`. Publishing is the only network-dependent action;
everything else is local form state.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILComposeEntity.swift` | Pure business fields: audience, body, tags, attachments (image / verse / session). |
| Domain / UseCase | `Domain/UseCases/Compose/ILComposeUseCase.swift` | `publish(post:)` (delegates to repository); `ILComposeError` maps failures. |
| Domain / Repository | `Domain/Repositories/ILComposeRepository.swift` | `publish(_:) async throws -> Void`. Entity in/out. |
| Data / Repository | `Data/Repositories/ILComposeRepositoryImpl.swift` | Wraps `NetworkService`; DTO ↔ Entity, `NetworkError` → `ILComposeError`. (Not yet created.) |
| Data / DTO + Mapper | `Data/DTOs/ILComposeDTO.swift` + `Data/DTOs/Mappers/ILComposeMapper.swift` | Wire shape for the publish request; Entity ↔ DTO. (Not yet created.) |
| Presentation / State | `Presentation/Scenes/Compose/ILComposeStateModel.swift` | UI-only state: audience, body, selected tags/attachments, publishing flag. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Compose/ILComposeViewModel.swift` | `Input -> Output`; owns `ILComposeNavEvent` (published, dismiss). |
| Presentation / Coordinator | `Presentation/Scenes/Compose/ILComposeCoordinator.swift` | Modally presents `ILComposeViewController`; dismisses on Đóng. |
| Presentation / ViewController | `Presentation/Scenes/Compose/ILComposeViewController.swift` | Header, audience rotator, composer, attachments, tags, publish button. |

## Navigation flow

```
SanghaCoordinator
  └─ (tap "viết bài") → ILSanghaNavEvent.openCompose → presentCompose() → ILComposeCoordinator
       present (sheet) ILComposeViewController
       (tap "Đăng lên đạo tràng") → publish → dismiss → Post/Sangha feed
       (tap Đóng) → dismiss
```

## Data flow

Single publish call, no multi-call sequence → Step-by-step Flow not required:

1. "Đăng lên đạo tràng" → `ILComposeViewModel.publish()` →
   `ILComposeRepository.publish(_:)` → on success emit `.published`, dismiss.

## Deliberately stubbed for now

`ILComposeUseCase.publish(post:)` is a one-line stub (`print("TODO: …")`) until
the publish API contract lands — see `requirements.md` Pending. No DTO / Mapper /
Endpoint / `ILComposeRepositoryImpl` exist yet (`tasks.md` Phase 3).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
screen `compose`, and `Mo-ta-tinh-nang.md` §6 "Viết bài chia sẻ".

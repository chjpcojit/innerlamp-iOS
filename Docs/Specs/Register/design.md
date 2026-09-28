# Design — Register

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; register API unconfirmed

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Register follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a **section
screen** owned by the Events coordinator, reached when the user taps "Ghi danh"
or an event. Submitting the registration is the single network-dependent action.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILRegisterEntity.swift` | Pure business fields: event id/name, time/location/instructor, groupSize, note. |
| Domain / UseCase | `Domain/UseCases/Register/ILRegisterUseCase.swift` | `register(...)` (delegates to repository); button-label derivation; `ILRegisterError` maps failures. |
| Domain / Repository | `Domain/Repositories/ILRegisterRepository.swift` | `register(_:) async throws -> Void`. Entity in/out. |
| Data / Repository | `Data/Repositories/ILRegisterRepositoryImpl.swift` | Wraps `NetworkService`; DTO ↔ Entity, `NetworkError` → `ILRegisterError`. (Not yet created.) |
| Data / DTO + Mapper | `Data/DTOs/ILRegisterDTO.swift` + `Data/DTOs/Mappers/ILRegisterMapper.swift` | Wire shape for the register request; Entity ↔ DTO. (Not yet created.) |
| Presentation / State | `Presentation/Scenes/Register/ILRegisterStateModel.swift` | UI-only state: group-size selection, button label, submitting flag, error. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Register/ILRegisterViewModel.swift` | `Input -> Output`; owns `ILRegisterNavEvent` (registered, back). |
| Presentation / Coordinator | `Presentation/Scenes/Register/ILRegisterCoordinator.swift` | Pushes `ILRegisterViewController`; forwards `registered` back to Events. |
| Presentation / ViewController | `Presentation/Scenes/Register/ILRegisterViewController.swift` | Header, details table, group-size selector, note, confirm button. |

## Navigation flow

```
EventsCoordinator
  └─ (tap "Ghi danh" / event) → showRegister(event:) → ILRegisterCoordinator
       push ILRegisterViewController
       (tap confirm) → register → pop back to Events
       (tap back) → pop
```

## Data flow

Single register call, no multi-call sequence → Step-by-step Flow not required:

1. Confirm → `ILRegisterViewModel.register()` → `ILRegisterRepository.register(_:)`
   → on success emit `.registered`, pop back to Events.

## Deliberately stubbed for now

`ILRegisterUseCase.register(...)` is a one-line stub (`print("TODO: …")`) until
the register API contract lands — see `requirements.md` Pending. No DTO / Mapper
/ Endpoint / `ILRegisterRepositoryImpl` exist yet (`tasks.md` Phase 3).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
screen `register`, and `Mo-ta-tinh-nang.md` §6 "Ghi danh".

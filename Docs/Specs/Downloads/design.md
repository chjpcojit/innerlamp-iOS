# Design — Downloads

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; catalog source unconfirmed

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Downloads follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a
**cross-section screen** reached from Settings (`openDownloads`) and from
Reader/SutraDetail "Tải về". It is a read-mostly list over local download
records, so most of its state is local; only the catalog that populates it needs
a source, which is still unconfirmed.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILDownloadsEntity.swift` | Pure business fields for one download item: id, kind, title, sizeBytes, durationSeconds, status (downloaded / downloading(progress) / waitingForWiFi). |
| Domain / UseCase | `Domain/UseCases/Downloads/ILDownloadsUseCase.swift` | `loadDownloads()` (delegates to repository), `storageUsage()` (local), `openItem(id:)` metadata. |
| Domain / Repository | `Domain/Repositories/ILDownloadsRepository.swift` | `listDownloads() async throws -> [ILDownloadsEntity]` — abstracts the (unconfirmed) catalog source. |
| Data / Repository | `Data/Repositories/ILDownloadsRepositoryImpl.swift` | Wraps `NetworkService` (or local store once confirmed); DTO ↔ Entity. (Not yet created.) |
| Data / DTO + Mapper | `Data/DTOs/ILDownloadsDTO.swift` + `Data/DTOs/Mappers/ILDownloadsMapper.swift` | Wire shape for the catalog list; Entity ↔ DTO. (Not yet created.) |
| Presentation / State | `Presentation/Scenes/Downloads/ILDownloadsStateModel.swift` | UI-only state: item count, total size, storage-bar segments, per-item status text. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Downloads/ILDownloadsViewModel.swift` | `Input -> Output`; owns `ILDownloadsNavEvent` (openItem, back). |
| Presentation / Coordinator | `Presentation/Scenes/Downloads/ILDownloadsCoordinator.swift` | Pushes `ILDownloadsViewController`; forwards `openItem` to the owning section. |
| Presentation / ViewController | `Presentation/Scenes/Downloads/ILDownloadsViewController.swift` | Header, storage bar, item list with per-item state. |

## Navigation flow

```
SettingsCoordinator / (Reader, SutraDetail)
  └─ (tap "Tải về") → showDownloads() → ILDownloadsCoordinator
       push ILDownloadsViewController
       (tap item) → openReader/openPlayer → owning section
       (tap back) → pop
```

## Data flow

Single load, no multi-call sequence → Step-by-step Flow not required:

1. `viewDidLoad` → `ILDownloadsViewModel.load()` →
   `ILDownloadsRepository.listDownloads()` → render list + storage bar.
2. `openItem(id:)` navigates to Reader/Player; download progress itself is
   driven by the shared download engine (out of this feature's scope).

## Deliberately stubbed for now

`ILDownloadsUseCase.loadDownloads()` is a one-line stub (`print("TODO: …")`)
until the catalog source is confirmed — see `requirements.md` Pending. No DTO /
Mapper / Endpoint / `ILDownloadsRepositoryImpl` exist yet (`tasks.md` Phase 3).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
screen `downloads`, and `Mo-ta-tinh-nang.md` §7 "Tải về".

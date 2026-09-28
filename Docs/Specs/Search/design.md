# Design — Search

Version: 1.0
Last updated: 2026-09-27
Status: not started — prospective; search API unconfirmed

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Search follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a
**cross-section navigation** reached from the Library search bar (primary) and
the Help screen's search box. Because two sections open it, it is owned by the
parent that most naturally hosts a shared search — to be confirmed — but is
modeled here as a leaf screen opened by whichever coordinator presents it. The
shape follows the canonical Library feature.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILSearchEntity.swift` | Pure business fields for a search result: id, kind (sutra / talk / meditation), title, subtitle, metadata (has audio, duration), featured flag. |
| Domain / UseCase | `Domain/UseCases/Search/ILSearchUseCase.swift` | `search(keyword:)` and `requestContent(keyword:)` — both delegate to a repository. `ILSearchError` maps failures. |
| Domain / Repository | `Domain/Repositories/ILSearchRepository.swift` | `search(_:) async throws -> [ILSearchEntity]`, `requestContent(_:) async throws -> Void`. Entity in/out. |
| Data / Repository | `Data/Repositories/ILSearchRepositoryImpl.swift` | Wraps `NetworkService`; maps DTO ↔ Entity and `NetworkError` → `ILSearchError`. (Not yet created.) |
| Data / DTO + Mapper | `Data/DTOs/ILSearchDTO.swift` + `Data/DTOs/Mappers/ILSearchMapper.swift` | Wire shapes for search request/response; field-for-field Entity ↔ DTO. (Not yet created.) |
| Presentation / State | `Presentation/Scenes/Search/ILSearchStateModel.swift` | UI-only state: keyword, per-tab counts, results, `isEmpty`/`isSearching`/`error`. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Search/ILSearchViewModel.swift` | `Input -> Output`; owns `ILSearchNavEvent` (open result, submit request, cancel). |
| Presentation / Coordinator | `Presentation/Scenes/Search/ILSearchCoordinator.swift` | Pushes `ILSearchViewController`; forwards result navigation to the owning section coordinator. |
| Presentation / ViewController | `Presentation/Scenes/Search/ILSearchViewController.swift` | Search field, tab chips, results list, empty IL-State; `setupViews`/`setupConstraints`/`bindViewModel`. |

## Navigation flow

```
LibraryCoordinator (primary) / HelpCoordinator
  └─ (tap search) → showSearch() → ILSearchCoordinator
       push ILSearchViewController
       (tap result) → openReader/openTalk/openMeditationSetup → owning section
       (tap "Hủy"/back) → pop back
```

## Data flow

Single-call per action (no multi-call sequence → Step-by-step Flow not
required):

1. Submit keyword → `ILSearchViewModel.search()` → `ILSearchRepository.search(_:)`
   → render results + tab counts, or the empty state.
2. "Gửi yêu cầu bản kinh" → `ILSearchViewModel.requestContent()` →
   `ILSearchRepository.requestContent(_:)` → confirmation.

## Deliberately stubbed for now

`ILSearchUseCase.search(keyword:)` and `requestContent(keyword:)` are one-line
stubs (`print("TODO: …")`) until the backend contracts land — see
`requirements.md` Pending. The repository protocol is declared, but no DTO /
Mapper / Endpoint / `ILSearchRepositoryImpl` exist yet (`tasks.md` Phase 3).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`
screens `search` and `empty`, and `Mo-ta-tinh-nang.md` §3 "Tìm kiếm" / "Không có
kết quả".

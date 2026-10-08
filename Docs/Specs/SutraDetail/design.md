# Design — SutraDetail

Version: 1.2
Last updated: 2026-10-07
Status: in-progress — real sutra API wired; Reader/Player still mock; Download not built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

SutraDetail ("Chi tiết bài kinh") follows MVVM-C + Clean Architecture per
`AGENTS.md`. It is a **leaf screen with two child pushes** — Reader (`.openReader`)
and Player (`.openPlayer`) — and no delegate. It is created by
`ILLibraryCoordinator` (tapping a sutra row → `ILLibraryNavEvent.openItem(id:kind:)`
with `kind == .sutra`) and pushed onto the Library tab's `BaseNavigationController`.
It is parameterized by a `sutraID` (the server slug) and loads it with one network call.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILSutraDetailEntity.swift` | `ILSutraDetailChapterEntity` (id, number, title, lineCount), `ILSutraDetailSutraEntity` (title, original title, kind, tradition, collection, reference, purposes, daily chant, duration?, translator, source, license, line count, chapters), `ILSutraDetailEntity` (`sutra`). |
| Domain / Repository | `Domain/Repositories/ILSutraRepository.swift` | `loadSutra(id:)` (shared with Sutras). |
| Domain / UseCase | `Domain/UseCases/SutraDetail/ILSutraDetailUseCase.swift` | `loadSutra(id:) async throws`. |
| Data | `ILSutraDTO`, `ILSutraMapper`, `SutraDetailEndpoint`, `ILSutraRepositoryImpl` | `GET /v1/sutras/{id}`; maps `sections[]` of the preferred (Vietnamese) translation to chapters. |
| Presentation / State | `.../ILSutraDetailStateModel.swift` | UI-only state: kicker/title/original name/meta, chip models, description, translator/source/license text, TOC count + chapter models. No UIKit import. |
| Presentation / ViewModel | `.../ILSutraDetailViewModel.swift` | `Input -> Output`; owns `ILSutraDetailNavEvent`; loads on `viewDidLoad` (`.loading` → `.success` / `.failure`); Entity→StateModel formatting. |
| Presentation / Coordinator | `.../ILSutraDetailCoordinator.swift` | Leaf — unchanged. |
| Presentation / ViewController | `.../ILSutraDetailViewController.swift` | Hides the description, translator and TOC blocks when empty. |
| Feature-scoped views | `Views/ILSutraDetailHeroView.swift`, `ILSutraDetailChapterListView.swift` | Unchanged. |

## Navigation flow

```
ILLibraryCoordinator (Library tab)
  └─ showSutraDetail(sutraID) → ILSutraDetailCoordinator   (no delegate)
       push ILSutraDetailViewController
       (.back) → pop + finish()
       (.openReader) → showReader() → ILReaderCoordinator
       (.openPlayer) → showPlayer() → ILPlayerCoordinator
       (.download) → TODO (Download screen not built)
```

## Data flow

1. `ILSutraDetailViewModel` emits `.loading`, calls `useCase.loadSutra(id:)` and maps the result to
   `ILSutraDetailStateModel` (kicker, "N dòng · duration", translator / source / license lines, chapter
   subtitles).
2. Nav taps emit `.back` / `.openReader` / `.download` / `.openPlayer`.

### Step-by-step Flow

1. Trigger: screen opens. API: `GET /v1/sutras/{id}` (public, no `Authorization`). Success:
   `data` = sutra + `review_status` + `translations[]` (with `source_name`, `source_url`, `note`,
   `sections[{name, start_n, line_count}]`). Failure: `404 SUTRA_NOT_FOUND` → `ILCatalogError.notFound`;
   no network → `.offline`; anything else → `.loadFailed`.

## Deliberately not wired

Audio / narrator / reading progress / section durations (TD-SutraDetail-002), Reader and Player
catalogs (TD-SutraDetail-003), `.download` (TODO).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
block `isDetail`. See `InnerLamp/Presentation/Scenes/SutraDetail/README.md` for
the full design-vs-implementation comparison and changelog.

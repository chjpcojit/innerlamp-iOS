# Design — SutraDetail

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full detail screen with static catalog; Download not built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

SutraDetail ("Chi tiết bài kinh") follows MVVM-C + Clean Architecture per
`AGENTS.md`. It is a **leaf screen with two child pushes** — Reader (`.openReader`)
and Player (`.openPlayer`) — and no delegate. It is created by
`ILLibraryCoordinator` (tapping a sutra row → `ILLibraryNavEvent.openItem(id:kind:)`
with `kind == .sutra`) and pushed onto the Library tab's `BaseNavigationController`.
It is parameterized by a `sutraID`. There is **no network** — the UseCase
returns a static catalog.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILSutraDetailEntity.swift` | `ILSutraDetailChapterEntity` (id, roman number, title, verse range, duration), `ILSutraDetailTag` (daily / phonetic), `ILSutraDetailSutraEntity` (kicker, title, narrator, chapter/verse counts, duration, description, tags, chapters), `ILSutraDetailEntity` (sutras, `currentSutraID`, `currentChapterID`, `readingProgress`). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/SutraDetail/ILSutraDetailUseCase.swift` | `getInitialState(sutraID:)` (static 1-sutra + 5-chapter catalog, fallback to first), `currentSutra(in:)`. Pure logic. |
| Presentation / State | `Presentation/Scenes/SutraDetail/ILSutraDetailStateModel.swift` | UI-only state: kicker/title/meta, tag models, progress title/percent/value, description, TOC count, chapter models. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/SutraDetail/ILSutraDetailViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILSutraDetailNavEvent` (`.back`, `.openReader`, `.download`, `.openPlayer`); Entity→StateModel mapping + duration formatting. |
| Presentation / Coordinator | `Presentation/Scenes/SutraDetail/ILSutraDetailCoordinator.swift` | Leaf — `pushViewController`; `.back` → pop+finish; `.openReader` → `showReader()`; `.openPlayer` → `showPlayer()`; `.download` → TODO. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/SutraDetail/ILSutraDetailViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/SutraDetail/Views/ILSutraDetailHeroView.swift`, `ILSutraDetailChapterListView.swift` | Hero and chapter-list views. |
| Shared tokens | `DesignSystem/Tokens/ILTypography.swift` + `ILColors.swift` | `contentHeroTitle` (Lora 29px), `scriptureDescription` (Lora 14px), `ILColors.goldOnDark`. |

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

1. `ILSutraDetailViewModel` loads `useCase.getInitialState(sutraID:)` and maps
   the sutra + chapters to `ILSutraDetailStateModel` (formatted meta, progress
   percent, chapter subtitle/duration).
2. Nav taps emit `.back` / `.openReader` / `.download` / `.openPlayer`.

There is no network call and no Step-by-step Flow.

## Deliberately mock / stub

The catalog is a static 1-sutra (Kinh Pháp Cú, 5 chapters) built in
`ILSutraDetailUseCaseImpl.makeSutraCatalog()`. `readingProgress` is a sample
`0.34`. `.download` is a TODO. Completing these is `tasks.md` Phase 3.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
block `isDetail`. See `InnerLamp/Presentation/Scenes/SutraDetail/README.md` for
the full design-vs-implementation comparison and changelog.

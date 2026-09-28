# Design — Reader

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — bilingual verse reading + playback UI with a static
catalog; destinations not built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Reader ("Tụng kinh") follows MVVM-C + Clean Architecture per `AGENTS.md`. It is
a **leaf screen** for back/share/download/font-size, but it pushes the **Player**
feature on `.openPlayer`. It is created by `ILLibraryCoordinator` (tapping a
sutra row → `ILLibraryNavEvent.openItem(id:kind:)` with `kind == .sutra`); when
`ILSutraDetailCoordinator` is built, the flow will become lib → detail → reader.
It is parameterized by a `sutraID`. There is **no network** — the UseCase
returns a static catalog.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILReaderEntity.swift` | `ILReaderVerseEntity` (vietnamese + english), `ILReaderSutraEntity` (title, subtitle, narrator, totalDurationSeconds, verses), `ILReaderEntity` (sutras, `currentSutraID`, `currentVerseIndex`, `readingProgress`, `elapsedSeconds`, `playbackSpeed`, `isPlaying`). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Reader/ILReaderUseCase.swift` | `getInitialState(sutraID:)` (static 1-sutra catalog, fallback to first), `currentSutra` / `currentVerse` / `nextVerse`, `togglePlayPause` (in-memory). Pure logic. |
| Presentation / State | `Presentation/Scenes/Reader/ILReaderStateModel.swift` | UI-only state: title/subtitle, reading progress, verse + translation, next-verse preview, now-playing text, elapsed/speed text, playback progress, isPlaying. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Reader/ILReaderViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILReaderNavEvent` (`.back`, `.openFontSize`, `.share`, `.download`, `.openPlayer`); Entity→StateModel mapping + time formatting. |
| Presentation / Coordinator | `Presentation/Scenes/Reader/ILReaderCoordinator.swift` | Leaf for back; `.openPlayer` → `showPlayer()` (pushes Player); `.openFontSize`/`.share`/`.download` → TODO. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/Reader/ILReaderViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/Reader/Views/ILReaderVerseView.swift`, `ILReaderPlaybackBarView.swift` | Verse block and playback bar. |
| Shared component | `DesignSystem/Components/ILPlayPauseButton.swift` | Round play/pause button (reused by Player/Talk later). |
| Shared token | `DesignSystem/Tokens/ILTypography.swift` | `readerVerse` (Lora 21px), `readerTranslation` (Lora 13.5px italic). |

## Navigation flow

```
ILLibraryCoordinator (Library tab)
  └─ showReader(sutraID) → ILReaderCoordinator          (no delegate)
       push ILReaderViewController
       (.back) → pop + finish()
       (.openPlayer) → showPlayer() → ILPlayerCoordinator (push full-screen player)
       (.openFontSize / .share / .download) → TODO
```

## Data flow

1. `ILReaderViewModel` loads `useCase.getInitialState(sutraID:)` and maps the
   current sutra/verse to `ILReaderStateModel` (formatted time/speed/now-playing
   labels, playback progress from `elapsedSeconds` / `totalDurationSeconds`).
2. `handlePlayPauseTapped()` → `togglePlayPause` flips `isPlaying` in memory.
3. Nav taps emit `.back` / `.openFontSize` / `.share` / `.download` /
   `.openPlayer`.

There is no network call and no Step-by-step Flow.

## Deliberately mock / stub

The catalog is a static 1-sutra (Kinh Pháp Cú, 2 verses) built in
`ILReaderUseCaseImpl.makeSutraCatalog()`; other Library sutras have no verse
data yet. `isPlaying` is in-memory (no real audio). The font-size / share /
download destinations are TODO. Completing these is `tasks.md` Phases 3–4.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
block `isReader`. See `InnerLamp/Presentation/Scenes/Reader/README.md` for the
full design-vs-implementation comparison and changelog.

# Design — Player

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full-screen player UI with in-memory playback state

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Player follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a **leaf
screen** — `ILPlayerCoordinator` has no delegate. It is pushed from two parents
via their existing `.openPlayer` nav event: `ILReaderCoordinator` (the "1.0×"
speed button) and `ILSutraDetailCoordinator` (the "Mở trình phát" action). It is
parameterized by a `sutraID`. There is **no network** and **no real audio** —
playback state is in-memory.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILPlayerEntity.swift` | `ILPlayerTrackEntity` (id, title, subtitle, totalDurationSeconds), `ILPlayerEntity` (tracks, `currentTrackID`, `elapsedSeconds`, `playbackSpeedIndex`, `sleepTimerIndex`, `isPlaying`). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Player/ILPlayerUseCase.swift` | `getInitialState(sutraID:)` (static 1-track catalog, fallback to first), `currentTrack(in:)`, `togglePlayPause`, `rewind`/`forward` (clamped), `selectSpeed`/`selectSleepTimer` (clamped). Pure in-memory logic. |
| Presentation / State | `Presentation/Scenes/Player/ILPlayerStateModel.swift` | UI-only state: header, track title/subtitle, elapsed/remaining/progress, isPlaying, seek labels, speed + sleep options + indices, sleep note. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Player/ILPlayerViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILPlayerNavEvent` (`.back`, `.openTableOfContents`); Entity→StateModel mapping + time/sleep-note formatting. |
| Presentation / Coordinator | `Presentation/Scenes/Player/ILPlayerCoordinator.swift` | Leaf — `pushViewController`; `.back` → pop+finish; `.openTableOfContents` → TODO. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/Player/ILPlayerViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/Player/Views/ILPlayerArtworkView.swift`, `ILPlayerOptionRowView.swift` | Artwork and option-row views. |
| Shared components/tokens | `ILPlayPauseButton.swift` (`glyphColor`), `ILImmersiveBackgroundView.swift` (`.player` style), `ILColors` / `ILTypography.playerTitle` | Reused + extended for the player. |

## Navigation flow

```
ILReaderCoordinator (speed button)         ILSutraDetailCoordinator ("Mở trình phát")
  └─ showPlayer() → ILPlayerCoordinator            (leaf, no delegate)
       push ILPlayerViewController
       (.back) → pop + finish()
       (.openTableOfContents) → TODO
```

## Data flow

1. `ILPlayerViewModel` loads `useCase.getInitialState(sutraID:)` and maps the
   track to `ILPlayerStateModel` (formatted elapsed/remaining, progress, speed +
   sleep options, sleep note).
2. `handlePlayPauseTapped` / `rewind` / `forward` / `selectSpeed` /
   `selectSleepTimer` mutate the entity and re-emit.
3. `backTapped` / `tableOfContentsTapped` → emit `.back` / `.openTableOfContents`.

There is no network call and no Step-by-step Flow.

## Deliberately mock / stub

The catalog is a static 1-track (Kinh Pháp Cú) built in
`ILPlayerUseCaseImpl.makeTrackCatalog()`; playback/seek/speed/sleep only mutate
in-memory state (no real audio). Completing these is `tasks.md` Phase 3, blocked
on the sutra-audio contract.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
screen `player`. See `InnerLamp/Presentation/Scenes/Player/README.md` for the
full design-vs-implementation comparison and changelog.

# Design — Reader

Version: 1.1
Last updated: 2026-10-03
Status: in-progress — scrolling chant view with a static catalog; simulated
playback

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Reader ("Tụng kinh") follows MVVM-C + Clean Architecture per `AGENTS.md`. It is
a **leaf screen**: its only navigation event is `.back`. It is created by
`ILSutraDetailCoordinator` (`openReader`) and `ILLibraryCoordinator`
(`kind == .sutra`), parameterized by `sutraID`. There is **no network** — the
UseCase returns a static catalog.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILReaderEntity.swift` | `ILReaderCue`, `ILReaderLineEntity`, `ILReaderSectionEntity`, `ILReaderSutraEntity` (title, narrator, hasAudio, duration, sections), `ILReaderEntity` (catalog, `currentSutraID`, `currentLineIndex`, `playbackSpeed`, `isPlaying`, `accumulatedMilliseconds`). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Reader/ILReaderUseCase.swift` | `getInitialState`, `currentSutra`, `togglePlayPause`, `seek(byLines:)`, `setSpeed`, `advance(byMilliseconds:)` (2.6 s per line at 1.0×), `progress`, `elapsedSeconds`. Pure logic. |
| Presentation / State | `ILReaderStateModel.swift` | Rows (heading / line with `isCurrent`), status/hint texts, settings + theme + font-size indexes, auto-scroll flag, position/duration/progress, speed chips. No UIKit. |
| Presentation / ViewModel | `ILReaderViewModel.swift` | `Input -> Output`; owns UI preferences (font size, theme, panel, auto-scroll); consumes an injectable tick publisher (default 0.25 s timer); `ILReaderNavEvent.back`. |
| Presentation / Coordinator | `ILReaderCoordinator.swift` | Pop + `finish()` on `.back`. |
| Presentation / ViewController | `ILReaderViewController.swift` | Header (`ILNavBar` + auto-scroll row + settings panel), `UITableView` of rows, legend footer, controls; forces light/dark per theme; keeps screen awake; auto-scroll to the current row. |
| Feature-scoped views | `Views/ILReaderLineCell`, `ILReaderHeadingCell`, `ILReaderAutoScrollRowView`, `ILReaderSettingsPanelView`, `ILReaderControlsView`, `ILReaderPalette` | Line/heading rows, toggle row, size/background panel, bottom controls, theme → colors. |
| Shared components/tokens | `ILPlayPauseButton`; `ILColors.Reader.*` (+ 6 assets `ILReader*`); `ILTypography.readerLineFonts/readerGloss/readerCue/readerOptionSize`; `ILMetrics.radiusOptionTile/radiusLineHighlight` | Reused / added for this screen. |

## Navigation flow

```
ILSutraDetailCoordinator / ILLibraryCoordinator
  └─ ILReaderCoordinator   (no delegate)
       push ILReaderViewController
       (.back) → pop + finish()
```

## Data flow

1. `ILReaderViewModel` loads `getInitialState(sutraID:)` and maps the current
   sutra to rows (headings count as rows, not lines) plus labels.
2. A tick every 0.25 s calls `advance(byMilliseconds: 250)`; the highlight moves
   when the scaled accumulator reaches 2600 ms.
3. Taps update the entity (play, seek, pace) or UI preferences (panel, size,
   theme, auto-scroll) and re-publish the state.
4. The view reloads the table when text/theme/size changes, otherwise only
   cross-fades the affected visible cells; it scrolls to the current row when
   auto-scroll is on.

There is no network call and no Step-by-step Flow.

## Deliberately mock / stub

Static catalog (text for 2 sutras), timer-driven highlight, no audio, in-memory
preferences. See `Docs/Tech-Debt/Reader/` and `Docs/Assumptions/Reader/`.

## Design reference

Matches `Docs/InnerLamp project/InnerLamp Prototype.dc.html`, block `isReader`.
See `InnerLamp/Presentation/Scenes/Reader/README.md` for status.

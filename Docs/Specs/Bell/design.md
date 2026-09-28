# Design — Bell

Version: 1.0
Last updated: 2026-09-27
Status: implemented — full in-memory practice tool with real audio

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Bell ("Chuông mõ") follows MVVM-C + Clean Architecture per `AGENTS.md`. It is a
**leaf screen** — `ILBellCoordinator` has no delegate and only handles
`.goBack`. It is created by `ILHomeCoordinator` (the "Chuông mõ" card on Home)
and pushed onto the Home tab's `BaseNavigationController`. There is **no
network**; all logic is pure in-memory, and audio is routed through a
Presentation-layer protocol (`ILPracticeSoundPlaying`), keeping the Domain layer
framework-free.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILBellEntity.swift` | Pure business fields: `mode`, `bpm`, `gapSeconds`, `everyCount`, `presetIndex`, `moCount`, `bellCount`, `isRunning`, `isRolling`. Plus `ILBellMode` (mo / bell / moAndBell) and `ILBellPreset`. No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Bell/ILBellUseCase.swift` | Pure rules: `presets` / `everyOptions`, `getInitialState()`, `selectPreset` / `selectMode` / `selectEvery` / `adjustRate` (clamping bpm 40–160, gap 5–120), `strikeMo` / `strikeBell`, `shouldRingBellAfterMo`, `resetCounters`, `setRunning` / `setRolling`, `intervalSeconds(for:)`. No persistence, no audio. |
| Presentation / State | `Presentation/Scenes/Bell/ILBellStateModel.swift` | UI-only state: resolved `.localized` labels, formatted rate/count strings, raw counts for strike detection, playback flags. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Bell/ILBellViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILBellNavEvent` (`.goBack`); owns the steady-rhythm `Timer` and the `DispatchWorkItem` roll; routes every strike through `ILPracticeSoundPlaying`; Entity→StateModel mapping. |
| Presentation / Coordinator | `Presentation/Scenes/Bell/ILBellCoordinator.swift` | Leaf — `pushViewController`; `.goBack` → pop + `finish()`. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/Bell/ILBellViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`; haptic feedback per strike; hides/shows bottom nav. |
| Core / Audio | `Core/Audio/ILPracticeSoundPlaying.swift`, `Core/Audio/ILPracticeSoundPlayer.swift` | `AVAudioPlayer` pool per sound (no cut-off during the roll); bundled `bell_strike.m4a`, `mo_strike.m4a`, `bead_click.m4a`. |
| Feature-scoped views | `Presentation/Scenes/Bell/Views/ILBellChipView.swift`, `ILBellModeSegmentedView.swift`, `ILBellPadView.swift`, `ILBellRateCardView.swift`, `ILBellActionBarView.swift` | The five immersive-med-specific views. |

## Navigation flow

```
ILHomeCoordinator (Home tab)
  └─ showBell() → ILBellCoordinator                       (leaf, no delegate)
       push ILBellViewController                          (hides ILBottomNavBar)
       (.goBack) → pop + finish()
```

## Data flow

Bell is entirely synchronous and in-memory:

- Tap/rhythm/roll strikes → `useCase.strikeMo`/`strikeBell` mutate the entity;
  the ViewModel routes the sound through `soundPlayer` and re-emits state.
- Steady rhythm: `startAutoTick()` schedules a repeating one-shot `Timer` at
  `useCase.intervalSeconds(for:)`; each tick strikes and re-schedules.
- "Dồn mõ" roll: 16 `DispatchWorkItem` strikes at 440 ms × 0.8 (min 70 ms), then
  one bell; cancelled by `cancelRoll()`.
- Auto-bell: after a mõ strike, `shouldRingBellAfterMo` schedules a delayed bell
  (0.18 s) when the count hits the `everyCount` milestone in `moAndBell` mode.

There is no network call and no Step-by-step Flow.

## Deliberately not implemented / persistence gap

Nothing is stubbed: all logic is real, but session state (mode / preset /
rhythm / counters) is **not persisted** — it resets on every open (same as
Mala). A local Repository would be added alongside a real need (`tasks.md`).
The `Timer`/`DispatchQueue` timing is not unit-tested (side effects); the pure
decisions behind it are covered by the UseCase tests.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`, the
`bell` screen; themed via the `--il-med-*` token set (light + dark). See
`InnerLamp/Presentation/Scenes/Bell/README.md` for the full
design-vs-implementation comparison and changelog.

---
type: Feature
title: Bell
description: Bell-and-wooden-fish practice tool — a full-screen, in-memory strike pad with presets, mode selector, rate adjuster, steady rhythm, and a 16-strike accelerating roll, playing real bundled audio.
resource: InnerLamp/Presentation/Scenes/Bell/
tags: [practice, audio, mvvm-c]
status: draft
generated: { by: claude-code, at: 2026-09-27T14:54:58+07:00 }
sources:
  - path: Docs/Specs/Bell/requirements.md
    kind: spec
  - path: Docs/Specs/Bell/design.md
    kind: spec
  - path: InnerLamp/Domain/UseCases/Bell/ILBellUseCase.swift
    kind: code
  - path: InnerLamp/Core/Audio/ILPracticeSoundPlayer.swift
    kind: code
---

# Summary

Bell ("Chuông mõ") is a full-screen immersive practice tool reached from the
Home "Chuông mõ" card. The user strikes a center pad (wooden fish in mõ mode,
bell in bell mode), picks one of five presets, switches mode (Mõ / Chuông / Mõ +
chuông), changes the auto-bell milestone, and nudges the rate; a play toggle runs
a steady auto-rhythm, and the left action runs a 16-strike accelerating roll that
ends in a bell. Every strike plays real bundled audio (`bell_strike.m4a` /
`mo_strike.m4a` via `ILPracticeSoundPlayer`) and haptics fire per strike.

All logic is pure in-memory and real — there are no stubs. Audio is routed
through a Presentation-layer protocol (`ILPracticeSoundPlaying`), keeping the
Domain layer framework-free. Session state is **not persisted** and there is no
sound/volume picker, which is why this concept stays `draft`.

# Architecture

MVVM-C + Clean Architecture. `ILBellCoordinator` is a **leaf** (no delegate, only
`.goBack`), created by `ILHomeCoordinator` and pushed onto the Home tab's
`BaseNavigationController`.

| Layer | Type | File |
|---|---|---|
| Domain / Entity | Domain Entity | `Domain/Entities/ILBellEntity.swift` — `mode`, `bpm`, `gapSeconds`, `everyCount`, `presetIndex`, `moCount`, `bellCount`, `isRunning`, `isRolling`; plus `ILBellMode` (mo / bell / moAndBell) and `ILBellPreset` |
| Domain / UseCase | UseCase | `Domain/UseCases/Bell/ILBellUseCase.swift` — pure rules: presets / everyOptions, `getInitialState()`, `selectPreset` / `selectMode` / `selectEvery` / `adjustRate` (clamps bpm 40–160, gap 5–120), `strikeMo` / `strikeBell`, `shouldRingBellAfterMo`, `resetCounters`, `setRunning` / `setRolling`, `intervalSeconds(for:)` |
| Presentation / State | State Model | `Presentation/Scenes/Bell/ILBellStateModel.swift` — UI-only resolved labels, formatted strings, playback flags |
| Presentation / ViewModel | ViewModel | `Presentation/Scenes/Bell/ILBellViewModel.swift` — `Input -> Output`; owns the steady-rhythm `Timer` and the `DispatchWorkItem` roll; routes every strike through `ILPracticeSoundPlaying` |
| Presentation / Coordinator | Coordinator | `Presentation/Scenes/Bell/ILBellCoordinator.swift` — leaf; `.goBack` → pop + finish |
| Presentation / ViewController | ViewController | `Presentation/Scenes/Bell/ILBellViewController.swift` — haptics per strike; hides/shows bottom nav |
| Core / Audio | Audio | `Core/Audio/ILPracticeSoundPlaying.swift`, `ILPracticeSoundPlayer.swift` — `AVAudioPlayer` pool (no cut-off during roll); bundled `bell_strike.m4a`, `mo_strike.m4a`, `bead_click.m4a` |
| Feature-scoped views | View | `Presentation/Scenes/Bell/Views/ILBellChipView.swift`, `ILBellModeSegmentedView.swift`, `ILBellPadView.swift`, `ILBellRateCardView.swift`, `ILBellActionBarView.swift` |
| Tests | Unit tests | `InnerLampTests/ILBellViewModelTests.swift` (12 ViewModel + 11 UseCase tests, `MockILBellUseCase` / `MockILPracticeSoundPlayer`) |

# Navigation

```
ILHomeCoordinator (Home tab)
  └─ showBell() → ILBellCoordinator                      (leaf, no delegate)
       push ILBellViewController                         (hides ILBottomNavBar)
       (.goBack) → pop + finish()
```

# Behavior rules

- Bell-only mode adjusts the gap by ±5s (clamped 5…120); other modes adjust bpm
  by ±4 (clamped 40…160); a running rhythm is re-timed to the new interval.
- Auto-bell: after a mõ strike, `shouldRingBellAfterMo` schedules a delayed bell
  (0.18s) when the count hits the `everyCount` milestone in `moAndBell` mode.
- "Dồn mõ" roll: 16 `DispatchWorkItem` strikes at 440ms × 0.8 (min 70ms), then a
  bell; cancelled by `cancelRoll()`.
- The `Timer`/`DispatchQueue` timing is not unit-tested (side effects); the pure
  decisions behind it are covered by the UseCase tests.

# Pending work

- **Persistence**: session state (mode / preset / rhythm / counters) resets on
  every open — no local Repository (UserDefaults / Core Data). Added alongside a
  real need.
- **Sound / volume picker**: strikes play real bundled audio, but there is no
  user-facing control for volume or choosing a different sound.
  > ⚠️ Not confirmed: whether sound selection / volume is in Bell's scope or a
  > global settings concern.
- Promote to `stable` once persistence and the sound picker land and are
  exercised end-to-end.

# Related concepts

- [Home](home.md) (`InnerLamp/Presentation/Scenes/Home/`) — reached via the
  "Chuông mõ" card (`openBell`).
- `ILPracticeSoundPlayer` (`InnerLamp/Core/Audio/`) is shared with the Mala
  feature (no OKF concept yet) via `DIContainer.makePracticeSoundPlayer()`.

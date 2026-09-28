# Design — Mala

Version: 1.0
Last updated: 2026-09-27
Status: implemented — full-screen bead counter with audio feedback

> See `changelog.md` in this folder for the version history of this spec.

## Overview

Mala ("Tràng hạt · Niệm Phật") follows MVVM-C + Clean Architecture per
`AGENTS.md`. It is a **leaf screen** — `ILMalaCoordinator` has no delegate. It
is created by `ILHomeCoordinator` (the "Toàn màn hình" link on the Home bead
card) and pushed onto the Home tab's `BaseNavigationController`. There is **no
network**; the counter is in-memory, and audio is routed through the
Presentation-layer `ILPracticeSoundPlaying` protocol.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILMalaEntity.swift` | `ILMalaEntity` (`count`, `goal` = 108, `completedRounds`, `quarterInterval`) and `ILMalaMilestone` (`.quarter`, `.roundComplete`). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Mala/ILMalaUseCase.swift` | `getInitialState()`, `advanceBead(_:)` (wrap 108 → 1, +1 round), `resetBeads(_:)`, `milestone(for:)`. Pure logic, no persistence, no audio. |
| Presentation / State | `Presentation/Scenes/Mala/ILMalaStateModel.swift` | UI-only state: header title/subtitle ("N tràng"), count/goal/goalText, mantra/hint/footnote, action titles, `milestone`. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Mala/ILMalaViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILMalaNavEvent` (`.goBack`); plays `playBead()` / `playBell()` via `ILPracticeSoundPlaying`; Entity→StateModel mapping. |
| Presentation / Coordinator | `Presentation/Scenes/Mala/ILMalaCoordinator.swift` | Leaf — `pushViewController`; `.goBack` → pop + `finish()`. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/Mala/ILMalaViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`; haptic feedback per milestone; hides/shows bottom nav. |
| Core / Audio | `Core/Audio/ILPracticeSoundPlaying.swift`, `ILPracticeSoundPlayer.swift` | `playBead()` (soft click), `playBell()` (bell strike). |
| Shared components | `DesignSystem/Components/ILImmersiveBackgroundView.swift`, `ILMalaStrandView.swift`, `ILMalaCountDisplayView.swift`, `ILImmersiveActionBarView.swift` | Generic immersive components (background, strand, count display, action bar). |

## Navigation flow

```
ILHomeCoordinator (Home tab)
  └─ showMala() → ILMalaCoordinator               (leaf, no delegate)
       push ILMalaViewController                   (hides ILBottomNavBar)
       (.goBack) → pop + finish()
```

## Data flow

1. `ILMalaViewModel.handleBeadAdvanced()` → `useCase.advanceBead`, computes
   `milestone(for:)`, plays `playBead()` (and `playBell()` on round complete),
   re-emits state with the milestone.
2. `handleResetTapped()` → `resetBeads` (count → 0, rounds untouched).
3. `handleDoneTapped` / `handleBackTapped` → `.goBack`.

There is no network call and no Step-by-step Flow.

## Deliberately not implemented / persistence gap

The bead/round count is memory-only and resets on every open; it is not synced
with the Home bead counter. A local Repository would be added alongside a real
need (`tasks.md`). Audio is fixed (no volume/sound picker).

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
screen `mala`; themed via `--il-med-*`. See `InnerLamp/Presentation/Scenes/Mala/
README.md` for the full design-vs-implementation comparison and changelog.

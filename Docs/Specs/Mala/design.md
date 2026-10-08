# Design — Mala

Version: 1.1
Last updated: 2026-10-03
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
| Domain / Entity | `Domain/Entities/ILMalaEntity.swift` | `ILMalaEntity` (`count`, `goal` — one of `goalOptions` 21/54/108, `round` from 1, `isRoundComplete`, `quarterInterval`) and `ILMalaMilestone` (`.quarter`, `.roundComplete`). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/Mala/ILMalaUseCase.swift` | `getInitialState()`, `advanceBead(_:)` (stops at goal), `resetBeads(_:)`, `selectGoal(_:for:)` (count → 0), `startNextRound(_:)` (count → 0, round + 1), `milestone(for:)`. Pure logic, no persistence, no audio. |
| Presentation / State | `Presentation/Scenes/Mala/ILMalaStateModel.swift` | UI-only state: header title/subtitle ("Vòng N · biến x / goal") and "Xong" title, count/goal, `goalOptions` (chips), mantra, reset title, completion popup texts + `isRoundComplete`, `milestone`. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/Mala/ILMalaViewModel.swift` | `Input -> Output` per `ViewModelType` (adds `goalSelected`, `continueTapped`); owns `ILMalaNavEvent` (`.goBack`); plays `playBead()` / `playBell()` via `ILPracticeSoundPlaying`; Entity→StateModel mapping. |
| Presentation / Coordinator | `Presentation/Scenes/Mala/ILMalaCoordinator.swift` | Leaf — `pushViewController`; `.goBack` → pop + `finish()`. No delegate. |
| Presentation / ViewController | `Presentation/Scenes/Mala/ILMalaViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`; goal chips (reuses Bell's `ILBellChipView`), completion popup, haptic feedback per milestone; hides/shows bottom nav. |
| Core / Audio | `Core/Audio/ILPracticeSoundPlaying.swift`, `ILPracticeSoundPlayer.swift` | `playBead()` (soft click), `playBell()` (bell strike). |
| Presentation / View | `Presentation/Scenes/Mala/Views/ILMalaCompletionView.swift` | Feature-scoped "Tròn N biến" popup (dark card, `ILButton` gold + onDark). |
| Shared components | `DesignSystem/Components/ILImmersiveBackgroundView.swift`, `ILMalaStrandView.swift` (red cord + wooden beads), `ILMalaProgressBarView.swift`, `ILImmersiveActionBarView.swift` | Generic immersive components (background, strand, progress bar, action bar — primary button hidden when its title is empty). |

## Navigation flow

```
ILHomeCoordinator (Home tab)
  └─ showMala() → ILMalaCoordinator               (leaf, no delegate)
       push ILMalaViewController                   (hides ILBottomNavBar)
       (.goBack) → pop + finish()
```

## Data flow

1. `ILMalaViewModel.handleBeadAdvanced()` → `useCase.advanceBead`, computes
   `milestone(for:)`, plays `playBead()` (and `playBell()` when the goal is
   reached), re-emits state with the milestone; `isRoundComplete` shows the popup.
2. `handleGoalSelected` → `selectGoal` (goal changes, count → 0).
3. `handleContinueTapped` → `startNextRound` (count → 0, round + 1).
4. `handleResetTapped()` → `resetBeads` (count → 0, round and goal untouched).
5. `handleDoneTapped` / `handleBackTapped` → `.goBack`.

There is no network call and no Step-by-step Flow.

## Deliberately not implemented / persistence gap

The bead/round count is memory-only and resets on every open; it is not synced
with the Home bead counter. A local Repository would be added alongside a real
need (`tasks.md`). Audio is fixed (no volume/sound picker).

## Design reference

Matches `Docs/InnerLamp icon consistency/InnerLamp Prototype.dc.html`,
screen `mala` (v1.1; v1.0 followed the earlier `Docs/design_handoff_innerlamp/` handoff); themed via `--il-med-*`. See `InnerLamp/Presentation/Scenes/Mala/
README.md` for the full design-vs-implementation comparison and changelog.

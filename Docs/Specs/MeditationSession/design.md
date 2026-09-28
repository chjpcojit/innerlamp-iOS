# Design — MeditationSession

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — immersive sitting screen; `recordSession` stub, Done not built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MeditationSession ("Phiên thiền") follows MVVM-C + Clean Architecture per
`AGENTS.md`. It is **pushed** onto the practice-flow modal stack that
`ILMeditationSetupCoordinator` presents, after "Bắt đầu" (guided) or "Ngồi im
lặng" (silent). It is parameterized by `durationMinutes` and `isGuided`. It has
a delegate (`ILMeditationSessionCoordinatorDelegate`) because the parent must
react to `.finished`. There is **no network** — the only outbound action,
`recordSession`, is a stub.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILMeditationSessionEntity.swift` | `ILMeditationSessionEntity` (`durationSeconds`, `elapsedSeconds`, `isGuided`, `isRunning`; derived `remainingSeconds`, `isCompleted`, `breathPhase`, `secondsLeftInBreathPhase`) and `ILBreathPhase` (inhale/exhale). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/MeditationSession/ILMeditationSessionUseCase.swift` | `makeSession`, `tick`, `togglePause`, `endSession` (pure rules) and `recordSession` (stub). |
| Presentation / State | `Presentation/Scenes/MeditationSession/ILMeditationSessionStateModel.swift` | UI-only state: header title/subtitle, "mm:ss" countdown, cue lines (empty when silent), breath phase, isPlaying, accessibility labels. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/MeditationSession/ILMeditationSessionViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILMeditationSessionNavEvent` (`.goBack`, `.finished(elapsedSeconds:)`); injected 1s `ticker`; opening/closing bells via `ILPracticeSoundPlaying`; idempotent finish. |
| Presentation / Coordinator | `Presentation/Scenes/MeditationSession/ILMeditationSessionCoordinator.swift` | `pushViewController`; `.goBack` → pop+finish; `.finished` → delegate + finish. |
| Presentation / ViewController | `Presentation/Scenes/MeditationSession/ILMeditationSessionViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`; keeps screen awake. |
| Shared components | `DesignSystem/Components/ILBreathingRingView.swift`, `ILImmersiveTransportControlsView.swift` | Breathing ring + transport controls (Reduce Motion aware). |

## Navigation flow

```
ILMeditationSetupCoordinator (practice-flow modal)
  └─ .startSession(duration, guided) → ILMeditationSessionCoordinator
       push ILMeditationSessionViewController
       (.goBack)   → pop + finish()
       (.finished) → meditationSessionDidFinish → parent (TODO: Done screen → closeFlow)
```

## Data flow

1. `ILMeditationSessionViewModel` builds the session via `useCase.makeSession`
   and subscribes the injected 1s `ticker`.
2. `handleTick()` → `useCase.tick` advances `elapsedSeconds`; when `isCompleted`,
   `finishSession()` runs.
3. `finishSession()` (idempotent) → `endSession`, play closing bell, then
   `recordSession` (stub) and emit `.finished(elapsedSeconds:)`.
4. `handlePlayPauseTapped()` → `togglePause`; `handleBackTapped` → `.goBack`.

There is no network call and no Step-by-step Flow (the `recordSession` stub is
a single local persistence action, not a confirmed API).

## Deliberately stubbed for now

`ILMeditationSessionUseCaseImpl.recordSession` is a one-line `print("TODO: …")`
— the finished sit is not saved to a practice log. Completing this is
`tasks.md` Phase 3, blocked on the practice-log storage decision.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
screen `session`. See `InnerLamp/Presentation/Scenes/MeditationSession/README.md`
for the full design-vs-implementation comparison and changelog.

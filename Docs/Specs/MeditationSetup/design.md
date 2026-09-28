# Design — MeditationSetup

Version: 1.0
Last updated: 2026-09-27
Status: in-progress — full-screen setup modal; session flow wired, Done not built

> See `changelog.md` in this folder for the version history of this spec.

## Overview

MeditationSetup ("Chuẩn bị thiền") follows MVVM-C + Clean Architecture per
`AGENTS.md`. It is the **section coordinator of the practice flow**, not a leaf:
it presents a full-screen modal backed by its own `BaseNavigationController`,
and pushes `ILMeditationSessionCoordinator` onto that stack on `.startSession`.
It is reached from two parents — `ILMainTabCoordinator` (lamp button →
`onLampTapped`) and `ILHomeCoordinator` (meditation row → `.openMeditationSetup`)
— neither of which sets a delegate (the flow is open-and-forget). There is **no
network**; duration selection is in-memory.

## Layers & components

| Layer | File | Responsibility |
|---|---|---|
| Domain / Entity | `Domain/Entities/ILMeditationSetupEntity.swift` | `ILMeditationSetupEntity` (`durationOptions` [5,12,20,30,45], `durationMinutes` default 20). No UI-only state. |
| Domain / UseCase | `Domain/UseCases/MeditationSetup/ILMeditationSetupUseCase.swift` | `getInitialState()`, `selectDuration(_:in:)` (only accepts values in `durationOptions`). Pure logic. |
| Presentation / State | `Presentation/Scenes/MeditationSetup/ILMeditationSetupStateModel.swift` | UI-only state: resolved labels, `durationOptions`, `selectedDurationIndex`, "Bắt đầu · N phút" CTA, bell rows, tip. No UIKit import. |
| Presentation / ViewModel | `Presentation/Scenes/MeditationSetup/ILMeditationSetupViewModel.swift` | `Input -> Output` per `ViewModelType`; owns `ILMeditationSetupNavEvent` (`.startSession(durationMinutes:guided:)`, `.close`); Entity→StateModel mapping. |
| Presentation / Coordinator | `Presentation/Scenes/MeditationSetup/ILMeditationSetupCoordinator.swift` | Presents the full-screen modal (`BaseNavigationController`); `.startSession` → starts `ILMeditationSessionCoordinator` on the modal stack; `.close` → dismiss + finish; conforms to `ILMeditationSessionCoordinatorDelegate`. |
| Presentation / ViewController | `Presentation/Scenes/MeditationSetup/ILMeditationSetupViewController.swift` | `setupViews`/`setupConstraints`/`bindViewModel` per `BaseViewController`. |
| Feature-scoped views | `Presentation/Scenes/MeditationSetup/Views/ILMeditationSetupDurationView.swift`, `ILMeditationSetupBellCardView.swift`, `ILMeditationSetupTipView.swift` | Duration selector, bell card (3 static rows), tip card. |
| Shared token | `DesignSystem/Tokens/ILTypography.swift` | `optionChip` (16px medium). |

## Navigation flow

```
ILMainTabCoordinator  (lamp button)          ILHomeCoordinator (meditation row)
  └─ showMeditationSetup() → ILMeditationSetupCoordinator   (section coordinator)
       present full-screen modal (own BaseNavigationController)
       (.startSession(duration, guided)) → showMeditationSession(...)
             → ILMeditationSessionCoordinator (pushed on the modal stack)
             → .meditationSessionDidFinish → TODO (Done screen) → closeFlow()
       (.close) → closeFlow() → dismiss + finish()
```

## Data flow

1. `ILMeditationSetupViewModel` loads `useCase.getInitialState()` (default 20m)
   and maps to `ILMeditationSetupStateModel`.
2. `handleDurationSelected(minutes)` → `selectDuration` updates the entity and
   re-emits.
3. `handleStartTapped` / `handleSilentTapped` → emit `.startSession(duration,
   guided: true/false)`.

There is no network call and no Step-by-step Flow (the practice flow is
navigation across screens, not sequential API calls).

## Deliberately not implemented

Duration selection is in-memory (no persistence); the Done/Journal screen is a
TODO (`meditationSessionDidFinish` logs and dismisses); the bell rows are static.
See the ⚠️ in `requirements.md` Pending.

## Design reference

Matches `Docs/design_handoff_innerlamp/design/InnerLamp Prototype.dc.html`,
screen `setup`. See `InnerLamp/Presentation/Scenes/MeditationSetup/README.md`
for the full design-vs-implementation comparison and changelog.
